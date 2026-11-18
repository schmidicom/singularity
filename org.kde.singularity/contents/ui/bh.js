.pragma library

// Deterministic PRNG (mulberry32) so the disk looks identical on every start.
function rng(seed) {
    var s = seed >>> 0;
    return function () {
        s = (s + 0x6D2B79F5) >>> 0;
        var t = s;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

function clamp(x, a, b) { return Math.max(a, Math.min(b, x)); }

function smoothstep(e0, e1, x) {
    var t = clamp((x - e0) / (e1 - e0), 0, 1);
    return t * t * (3 - 2 * t);
}

// Temperature palettes, hot (inner edge) -> cool (outer edge).
var palettes = [
    // 0: Interstellar – warm white, gold, orange, deep red
    [[255, 250, 240], [255, 222, 160], [255, 168, 80], [228, 98, 34], [140, 40, 14]],
    // 1: Blue giant – white, ice blue, blue, indigo
    [[245, 250, 255], [190, 222, 255], [120, 166, 255], [70, 96, 236], [34, 34, 140]],
    // 2: Nebula – white, pink, violet, deep purple
    [[255, 245, 252], [255, 190, 238], [236, 120, 236], [160, 70, 230], [64, 24, 130]],
    // 3: Ember – pale gold, orange, red, crimson
    [[255, 238, 210], [255, 182, 110], [255, 110, 50], [205, 42, 28], [96, 10, 18]]
];

function rgb(scheme, u) {
    var p = palettes[clamp(scheme | 0, 0, palettes.length - 1)];
    u = Math.pow(clamp(u, 0, 1), 0.75) * (p.length - 1);
    var i = Math.min(Math.floor(u), p.length - 2);
    var f = u - i;
    return [
        p[i][0] + (p[i + 1][0] - p[i][0]) * f,
        p[i][1] + (p[i + 1][1] - p[i][1]) * f,
        p[i][2] + (p[i + 1][2] - p[i][2]) * f
    ];
}

function css(scheme, u, a) {
    var c = rgb(scheme, u);
    return "rgba(" + Math.round(c[0]) + "," + Math.round(c[1]) + "," + Math.round(c[2]) + "," + clamp(a, 0, 1).toFixed(4) + ")";
}
