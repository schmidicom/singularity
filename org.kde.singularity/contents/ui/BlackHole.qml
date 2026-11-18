import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "bh.js" as Bh

// The complete scene. Independent of Plasma, so it can also be tested with
// `qml BlackHole.qml` or embedded anywhere else.
//
// Layer order (back to front):
//   stars -> halo -> far half of the disk -> particles behind
//   -> lensed image of the disk -> shadow -> photon ring
//   -> near half of the disk -> particles in front
Item {
    id: root

    implicitWidth: 1600
    implicitHeight: 900

    // ---- public configuration ------------------------------------------------
    property real speed: 1.0          // 1.0 = normal
    property real tilt: 8             // viewing angle above disk plane, degrees
    property real holeScale: 1.0
    property real offsetX: 0          // fraction of width, -0.5 .. 0.5
    property int scheme: 0
    property int particleCount: 110
    property bool showStars: true
    property bool glow: true
    property bool running: true

    // ---- geometry ------------------------------------------------------------
    readonly property real cx: width / 2 + offsetX * width
    readonly property real cy: height / 2
    readonly property real rs: Math.min(width, height) * 0.082 * holeScale   // shadow radius
    readonly property real tiltFactor: Math.max(0.03, Math.sin(tilt * Math.PI / 180))
    readonly property var edges: [1.55, 1.95, 2.45, 3.05, 3.8, 4.7, 5.9]       // band edges in rs
    readonly property real diskIn: edges[0]
    readonly property real diskOut: edges[edges.length - 1]
    readonly property real feather: rs * 0.18
    readonly property real omega0: 0.55                                         // rad/s at inner edge

    function omegaAt(x) { return omega0 * Math.pow(diskIn / x, 1.5); }          // Kepler: w ~ r^-3/2

    // ---- clock ----------------------------------------------------------------
    property real t: 0
    FrameAnimation {
        running: root.running && root.visible
        onTriggered: root.t += Math.min(frameTime, 0.1) * root.speed
    }

    clip: true

    // ---- background -------------------------------------------------------------
    StarField {
        anchors.fill: parent
        z: 0
        scheme: root.scheme
        showStars: root.showStars
        running: root.running
        holeX: root.cx
        holeY: root.cy
        holeRadius: root.rs
    }

    // ---- soft halo around everything ----------------------------------------------
    Shape {
        anchors.fill: parent
        z: 1
        visible: root.glow
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.cx; centerY: root.cy; centerRadius: root.rs * 9
                focalX: root.cx; focalY: root.cy
                GradientStop { position: 0.0; color: Qt.rgba(...root.col(0.45, 0.20)) }
                GradientStop { position: 0.25; color: Qt.rgba(...root.col(0.65, 0.08)) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
            }
            PathSvg { path: "M0 0 H" + root.width + " V" + root.height + " H0 Z" }
        }
    }

    // flat glow in the plane of the disk
    Item {
        x: root.cx - width / 2; y: root.cy - height / 2
        width: root.rs * 16; height: width
        z: 1
        visible: root.glow
        transform: Scale { origin.x: root.rs * 8; origin.y: root.rs * 8; yScale: root.tiltFactor * 1.4 }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: root.rs * 8; centerY: root.rs * 8; centerRadius: root.rs * 8
                    focalX: centerX; focalY: centerY
                    GradientStop { position: 0.0; color: Qt.rgba(...root.col(0.3, 0.30)) }
                    GradientStop { position: 0.35; color: Qt.rgba(...root.col(0.6, 0.12)) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
                }
                PathSvg { path: "M0 0 H" + root.rs * 16 + " V" + root.rs * 16 + " H0 Z" }
            }
        }
    }

    function col(u, a) {
        var c = Bh.rgb(root.scheme, u);
        return [c[0] / 255, c[1] / 255, c[2] / 255, a];
    }

    // ---- the accretion disk (rendered once into a hidden layer) ----------------------
    readonly property real diskPad: rs * 1.2
    readonly property real diskW: 2 * (diskOut * rs + feather) + 2 * diskPad
    readonly property real diskH: 2 * (diskOut * rs + feather) * tiltFactor + 2 * diskPad

    Item {
        id: diskLayer
        // integer, even-sized geometry so the two halves meet without a seam
        x: Math.round(root.cx - width / 2)
        y: Math.round(root.cy) - height / 2
        width: 2 * Math.ceil(root.diskW / 2)
        height: 2 * Math.ceil(root.diskH / 2)
        visible: false
        layer.enabled: true

        Item {
            id: diskPlane
            width: 2 * (root.diskOut * root.rs + root.feather)
            height: width
            anchors.centerIn: parent
            transform: Scale {
                origin.x: diskPlane.width / 2
                origin.y: diskPlane.height / 2
                yScale: root.tiltFactor
            }

            Repeater {
                model: root.edges.length - 1
                delegate: DiskBand {
                    readonly property real mid: (root.edges[index] + root.edges[index + 1]) / 2
                    anchors.centerIn: parent
                    rs: root.rs
                    inner: root.edges[index] * root.rs
                    outer: root.edges[index + 1] * root.rs
                    feather: index === 0 ? root.rs * 0.08 : root.feather
                    seed: 1000 + index * 7919
                    scheme: root.scheme
                    peak: root.diskIn
                    rise: 0.18
                    falloff: 1.5
                    uIn: root.diskIn
                    uOut: root.diskOut
                    // differential (Keplerian) rotation; negative = counter-clockwise,
                    // so the left side moves towards the viewer
                    rotation: -(root.omegaAt(mid) * root.t * 180 / Math.PI) % 360
                }
            }

            // Relativistic beaming: approaching side (left) brighter, receding side dimmer.
            Canvas {
                id: doppler
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    if (width < 4)
                        return;
                    var c = width / 2;
                    var rs = root.rs;
                    // 1) left/right gradient
                    var g = ctx.createLinearGradient(0, 0, width, 0);
                    g.addColorStop(0.00, "rgba(255,250,240,0.10)");
                    g.addColorStop(0.30, "rgba(255,250,240,0.16)");
                    g.addColorStop(0.50, "rgba(0,0,0,0.0)");
                    g.addColorStop(0.70, "rgba(0,0,0,0.40)");
                    g.addColorStop(1.00, "rgba(0,0,0,0.70)");
                    ctx.fillStyle = g;
                    ctx.fillRect(0, 0, width, height);
                    // 2) keep it only where there is gas (radial mask)
                    ctx.globalCompositeOperation = "destination-in";
                    var m = ctx.createRadialGradient(c, c, 0, c, c, c);
                    var N = 16;
                    for (var i = 0; i <= N; ++i) {
                        var x = (c * i / N) / rs;
                        var a = Bh.smoothstep(root.diskIn - 0.1, root.diskIn + 0.3, x)
                              * Bh.smoothstep(root.diskOut + 0.2, root.diskOut - 1.5, x);
                        m.addColorStop(i / N, "rgba(0,0,0," + a.toFixed(3) + ")");
                    }
                    ctx.fillStyle = m;
                    ctx.fillRect(0, 0, width, height);
                    ctx.globalCompositeOperation = "source-over";
                }
            }
        }
    }

    // wide glow of the whole disk – lies behind the shadow, so it is never cut
    MultiEffect {
        z: 1.5
        x: diskLayer.x; y: diskLayer.y
        width: diskLayer.width; height: diskLayer.height
        source: diskLayer
        visible: root.glow
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 48
        blur: 1.0
        brightness: 0.1
        opacity: 0.8
    }

    // slightly softened disk, split in two halves around the shadow
    Item {
        id: diskComposite
        x: diskLayer.x; y: diskLayer.y
        width: diskLayer.width; height: diskLayer.height

        MultiEffect {
            anchors.fill: parent
            source: diskLayer
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: 8
            blur: 0.5
        }
    }

    // far half – behind the hole
    ShaderEffectSource {
        z: 2
        x: diskComposite.x; y: diskComposite.y
        width: diskComposite.width; height: diskComposite.height / 2
        sourceItem: diskComposite
        sourceRect: Qt.rect(0, 0, diskComposite.width, diskComposite.height / 2)
        hideSource: true
        live: true
    }

    // near half – in front of the hole
    ShaderEffectSource {
        z: 5
        x: diskComposite.x; y: diskComposite.y + diskComposite.height / 2
        width: diskComposite.width; height: diskComposite.height / 2
        sourceItem: diskComposite
        sourceRect: Qt.rect(0, diskComposite.height / 2, diskComposite.width, diskComposite.height / 2)
        hideSource: true
        live: true
    }

    // ---- gravitationally lensed image of the far side of the disk -------------------------
    // Light from the far side of the disk is bent over the top (and, fainter, under the
    // bottom) of the shadow. Modelled as a thin bright ring plus a broad arc that only
    // exists above the hole; both are faded with gradient masks.
    readonly property real lensSize: rs * 2 * 2.9

    Item {
        id: lensSrc
        x: root.cx - width / 2; y: root.cy - height / 2
        width: root.lensSize; height: width
        visible: false
        layer.enabled: true

        DiskBand {
            id: lensBand
            anchors.centerIn: parent
            rs: root.rs
            inner: root.rs * 1.06
            outer: root.rs * 1.5
            feather: root.rs * 0.18
            seed: 4242
            scheme: root.scheme
            peak: 1.14
            rise: 0.05
            falloff: 5.0
            baseAlpha: 0.95
            streakDensity: 0.8
            uIn: 1.15
            uOut: 4.5
            rotation: -(root.omegaAt(root.diskIn) * root.t * 180 / Math.PI * 0.8) % 360
        }
    }

    Item {
        id: arcSrc
        x: root.cx - width / 2; y: root.cy - height / 2
        width: root.lensSize; height: width
        visible: false
        layer.enabled: true

        Item {
            anchors.fill: parent
            transform: Scale { origin.x: arcSrc.width / 2; origin.y: arcSrc.height / 2; yScale: 0.82 }
            DiskBand {
                anchors.centerIn: parent
                rs: root.rs
                inner: root.rs * 1.25
                outer: root.rs * 2.75
                feather: root.rs * 0.3
                seed: 5151
                scheme: root.scheme
                peak: 1.35
                rise: 0.12
                falloff: 2.6
                baseAlpha: 0.8
                streakDensity: 1.2
                uIn: root.diskIn
                uOut: root.diskOut
                rotation: -(root.omegaAt(2.0) * root.t * 180 / Math.PI) % 360
            }
        }
    }

    // vertical masks: ring fades a bit towards the bottom, arc only lives above the hole
    Rectangle {
        id: ringMask
        width: root.lensSize; height: width
        visible: false
        layer.enabled: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 1) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 1) }
            GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.45) }
        }
    }
    Rectangle {
        id: arcMask
        width: root.lensSize; height: width
        visible: false
        layer.enabled: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 1) }
            GradientStop { position: 0.36; color: Qt.rgba(1, 1, 1, 1) }
            GradientStop { position: 0.49; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

    MultiEffect {
        z: 3
        x: arcSrc.x; y: arcSrc.y - root.rs * 0.05
        width: arcSrc.width; height: arcSrc.height
        source: arcSrc
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 16
        blur: 0.4
        maskEnabled: true
        maskSource: arcMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        opacity: 0.9
    }

    MultiEffect {
        z: 3.1
        x: lensSrc.x; y: lensSrc.y - root.rs * 0.04
        width: lensSrc.width; height: lensSrc.height
        source: lensSrc
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 16
        blur: 0.3
        brightness: 0.05
        maskEnabled: true
        maskSource: ringMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }


    // ---- the shadow (event horizon + photon capture region) ---------------------------------
    Rectangle {
        z: 4
        width: root.rs * 2; height: width; radius: width / 2
        x: root.cx - root.rs; y: root.cy - root.rs
        color: "black"
        antialiasing: true
    }

    // ---- photon ring --------------------------------------------------------------------------
    Item {
        z: 4.5
        width: root.rs * 2.6; height: width
        x: root.cx - width / 2; y: root.cy - height / 2
        layer.enabled: root.glow
        layer.effect: MultiEffect { blurEnabled: true; blurMax: 12; blur: 0.25; brightness: 0.2 }

        Rectangle {
            id: photonRing
            anchors.centerIn: parent
            width: root.rs * 2.04; height: width; radius: width / 2
            color: "transparent"
            antialiasing: true
            border.width: Math.max(1.2, root.rs * 0.022)
            border.color: Qt.rgba(...root.col(0.05, 0.9))
            opacity: 0.85 + 0.15 * Math.sin(root.t * 1.7)
        }
    }

    // ---- orbiting hot blobs ---------------------------------------------------------------------
    Repeater {
        model: root.particleCount
        delegate: Item {
            id: p
            readonly property var rnd: Bh.rng(31337 + index * 101)
            readonly property real rx: root.diskIn + 0.15 + Math.pow(rnd(), 1.6) * (root.diskOut - root.diskIn - 0.4)
            readonly property real phase: rnd() * Math.PI * 2
            readonly property real size: (0.025 + rnd() * rnd() * 0.07) * root.rs
            readonly property real hue: (rx - root.diskIn) / (root.diskOut - root.diskIn)
            readonly property real theta: phase - root.omegaAt(rx) * root.t
            readonly property real s: Math.sin(theta)
            readonly property real c: Math.cos(theta)
            readonly property real beam: Bh.clamp(0.55 - 0.45 * c, 0.1, 1.0)

            x: root.cx + rx * root.rs * c - width / 2
            y: root.cy + rx * root.rs * s * root.tiltFactor - height / 2
            width: size * 4; height: width
            z: s > 0 ? 5.5 : 2.5
            opacity: beam * Bh.smoothstep(root.diskOut, root.diskOut - 1.2, rx)

            Rectangle {
                anchors.centerIn: parent
                width: parent.width; height: width; radius: width / 2
                color: Qt.rgba(...root.col(p.hue, 0.07))
            }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.42; height: width; radius: width / 2
                color: Qt.rgba(...root.col(p.hue * 0.6, 0.35))
            }
            Rectangle {
                anchors.centerIn: parent
                width: p.size * 1.2; height: width; radius: width / 2
                color: Qt.rgba(...root.col(0, 0.95))
            }
        }
    }
}
