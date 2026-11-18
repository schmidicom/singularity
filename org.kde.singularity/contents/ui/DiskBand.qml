import QtQuick
import "bh.js" as Bh

// One annulus of hot gas. It is painted once (procedurally: a soft radial
// base plus a few hundred bright and dark arc-shaped streaks) and afterwards
// only rotated, which is practically free on the GPU. Several bands that
// rotate at different (Keplerian) speeds create the sheared, turbulent look.
Canvas {
    id: band

    property real rs: 50            // shadow radius in px (unit length)
    property real inner: 80         // px
    property real outer: 120        // px
    property real feather: 10       // px cross-fade with neighbouring bands
    property int seed: 1
    property int scheme: 0

    // radial intensity profile, in units of rs
    property real peak: 1.6
    property real rise: 0.2
    property real falloff: 1.6
    property real baseAlpha: 0.85
    property real streakDensity: 1.0

    // radius (in rs) mapped to the hottest / coolest palette colour
    property real uIn: 1.6
    property real uOut: 6.0

    readonly property real rA: Math.max(0, inner - feather)
    readonly property real rB: outer + feather

    width: 2 * rB
    height: width
    antialiasing: true

    onWidthChanged: requestPaint()
    onSchemeChanged: requestPaint()
    onInnerChanged: requestPaint()
    onSeedChanged: requestPaint()

    function u(r) { return (r / rs - uIn) / (uOut - uIn); }

    function weight(r) {
        if (feather <= 0)
            return 1;
        var a = Bh.clamp((r - rA) / (2 * feather), 0, 1);
        var b = Bh.clamp((rB - r) / (2 * feather), 0, 1);
        return a * b;
    }

    function intensity(r) {
        var x = r / rs;
        var s = Bh.smoothstep(peak - rise, peak + rise * 0.6, x);
        return s * Math.pow(peak / Math.max(x, peak * 0.5), falloff);
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        if (width < 4 || rs <= 0)
            return;

        var c = width / 2;
        var TAU = 2 * Math.PI;
        var rand = Bh.rng(seed);
        var i, r;

        // --- soft base glow -------------------------------------------------
        var g = ctx.createRadialGradient(c, c, rA, c, c, rB);
        var N = 14;
        for (i = 0; i <= N; ++i) {
            r = rA + (rB - rA) * i / N;
            g.addColorStop(i / N, Bh.css(scheme, u(r), baseAlpha * intensity(r) * weight(r)));
        }
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(c, c, rB, 0, TAU, false);
        if (rA > 0) {
            ctx.moveTo(c + rA, c);
            ctx.arc(c, c, rA, TAU, 0, true);
        }
        ctx.closePath();
        ctx.fill();

        // --- streaks (bright filaments and dark dust lanes) ------------------
        ctx.lineCap = "round";
        var n = Math.round(streakDensity * 420 * (rB - rA) / rs);
        for (i = 0; i < n; ++i) {
            r = rA + rand() * (rB - rA);
            var I = intensity(r) * weight(r);
            var a0 = rand() * TAU;
            var len = Math.min(TAU, (0.12 + rand() * rand() * 2.2) * (2.4 * rs / r));
            var dark = rand() < 0.28;
            var lw = Math.max(0.6, rs * (0.006 + rand() * rand() * 0.045));
            var hue = u(r) + (rand() - 0.5) * 0.18;
            var jitter = rand();
            if (I < 0.004)
                continue;

            if (dark) {
                ctx.globalCompositeOperation = "destination-out";
                ctx.strokeStyle = "rgba(0,0,0," + (0.15 + jitter * 0.5).toFixed(3) + ")";
            } else {
                ctx.globalCompositeOperation = "lighter";
                ctx.strokeStyle = Bh.css(scheme, hue, I * (0.06 + jitter * jitter * 0.7));
            }
            ctx.lineWidth = lw;
            ctx.beginPath();
            ctx.arc(c, c, r, a0, a0 + len, false);
            ctx.stroke();
        }

        // --- a few hot clumps -------------------------------------------------
        ctx.globalCompositeOperation = "lighter";
        var clumps = Math.round(streakDensity * 6 * (rB - rA) / rs);
        for (i = 0; i < clumps; ++i) {
            r = inner + rand() * (outer - inner);
            var a = rand() * TAU;
            var L = (0.25 + rand() * 0.5) * (2 * rs / r);
            var w = rs * (0.04 + rand() * 0.08);
            var k = intensity(r) * weight(r) * (0.25 + rand() * 0.35);
            for (var j = 0; j < 4; ++j) {
                ctx.lineWidth = w * (1 - j * 0.22);
                ctx.strokeStyle = Bh.css(scheme, u(r) - 0.15, k * 0.35);
                ctx.beginPath();
                ctx.arc(c, c, r, a, a + L * (1 - j * 0.2), false);
                ctx.stroke();
            }
        }
        ctx.globalCompositeOperation = "source-over";
    }
}
