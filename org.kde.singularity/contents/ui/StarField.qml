import QtQuick
import "bh.js" as Bh

// Deep-space background: faint nebula clouds and a static star field painted
// once, plus a handful of twinkling stars animated in QML.
Item {
    id: field

    property int scheme: 0
    property bool showStars: true
    property bool running: true
    property real holeX: width / 2
    property real holeY: height / 2
    property real holeRadius: 50

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#05060d" }
            GradientStop { position: 0.55; color: "#020208" }
            GradientStop { position: 1.0; color: "#000000" }
        }
    }

    Canvas {
        id: sky
        anchors.fill: parent
        visible: field.showStars
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: field
            function onSchemeChanged() { sky.requestPaint(); }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            if (width < 4 || height < 4)
                return;
            var rand = Bh.rng(7331);
            var i;

            // nebula clouds
            ctx.globalCompositeOperation = "lighter";
            for (i = 0; i < 7; ++i) {
                var nx = rand() * width, ny = rand() * height;
                var nr = (0.25 + rand() * 0.45) * Math.max(width, height);
                var g = ctx.createRadialGradient(nx, ny, 0, nx, ny, nr);
                var tint = Bh.rgb(field.scheme, 0.55 + rand() * 0.45);
                var mix = rand() < 0.4 ? [40, 70, 140] : tint;
                var a = 0.025 + rand() * 0.035;
                g.addColorStop(0, "rgba(" + Math.round(mix[0]) + "," + Math.round(mix[1]) + "," + Math.round(mix[2]) + "," + a + ")");
                g.addColorStop(1, "rgba(0,0,0,0)");
                ctx.fillStyle = g;
                ctx.fillRect(0, 0, width, height);
            }

            // stars
            var count = Math.round(width * height / 2600);
            var hx = field.holeX, hy = field.holeY, hr = field.holeRadius;
            for (i = 0; i < count; ++i) {
                var x = rand() * width, y = rand() * height;
                var m = Math.pow(rand(), 6);            // most stars are faint
                var size = 0.35 + m * 1.6;
                var alpha = 0.18 + m * 0.82;
                var t = rand();
                var col = t < 0.15 ? "200,215,255" : (t < 0.27 ? "255,225,190" : "245,245,255");

                // weak lensing: push stars outward near the hole (Einstein ring hint)
                var dx = x - hx, dy = y - hy, d = Math.sqrt(dx * dx + dy * dy);
                if (d < hr * 1.1)
                    continue;
                if (d < hr * 6) {
                    var push = hr * hr * 1.4 / d;
                    x += dx / d * push;
                    y += dy / d * push;
                }

                ctx.fillStyle = "rgba(" + col + "," + alpha.toFixed(3) + ")";
                ctx.beginPath();
                ctx.arc(x, y, size, 0, 2 * Math.PI, false);
                ctx.fill();
                if (m > 0.35) {
                    var hg = ctx.createRadialGradient(x, y, 0, x, y, size * 5);
                    hg.addColorStop(0, "rgba(" + col + "," + (alpha * 0.25).toFixed(3) + ")");
                    hg.addColorStop(1, "rgba(" + col + ",0)");
                    ctx.fillStyle = hg;
                    ctx.fillRect(x - size * 5, y - size * 5, size * 10, size * 10);
                }
            }
            ctx.globalCompositeOperation = "source-over";
        }
    }

    Repeater {
        model: field.showStars ? 40 : 0
        delegate: Rectangle {
            id: star
            readonly property var r: Bh.rng(911 + index * 17)
            readonly property real s: 1.2 + r() * 1.6
            x: r() * field.width
            y: r() * field.height
            width: s
            height: s
            radius: s / 2
            color: index % 5 === 0 ? "#dfe8ff" : "#ffffff"
            opacity: 0.2

            SequentialAnimation on opacity {
                running: field.running
                loops: Animation.Infinite
                PauseAnimation { duration: 500 + Math.random() * 6000 }
                NumberAnimation { to: 0.95; duration: 900 + Math.random() * 1600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.15; duration: 1200 + Math.random() * 2200; easing.type: Easing.InOutSine }
            }
        }
    }
}
