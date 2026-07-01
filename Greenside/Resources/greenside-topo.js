/**
 * Greenside — Topographic Contour Engine
 * ────────────────────────────────────────
 * Generates golf-course survey contours as animated inline SVG.
 *
 * How it works:
 *   1. mulberry32     — seeded PRNG, reproducible per seed value
 *   2. makeNoise      — seeded 2-D Perlin noise (gradient noise)
 *   3. fbm            — fractional Brownian motion (layered octaves)
 *                       gives the terrain its natural fractal quality
 *   4. contourLayer   — samples the height field into a grid, then runs
 *                       marching-squares to trace iso-elevation lines.
 *                       Lines bunch tight on steep grades, open on flats,
 *                       and close into concentric rings at peaks (greens/mounds).
 *   5. topoRamp       — maps elevation 0→1 to valley-teal → brand green
 *                       → lime → gold, matching the reference quilt/record.
 *   6. flowField      — composes one or two contour layers into an SVG
 *                       with an overscan frame that drifts via CSS animation,
 *                       so the terrain breathes without a JS render loop.
 *
 * Usage:
 *   // in a <script> tag or module:
 *   document.querySelector('.my-topo').innerHTML = flowField({
 *     w: 393, h: 852,          // frame dimensions (px)
 *     seed: 7,                 // integer — change for a different terrain
 *     levels: 18,              // contour iso-lines count
 *     freq: 3.0,               // terrain frequency — higher = more peaks
 *     sw: 1.05,                // base stroke width
 *     two: true,               // overlay a second, lighter field for depth
 *     dur: 64,                 // drift animation duration (seconds)
 *     dx: 18, dy: 13,          // max drift distance (px)
 *     opFrom: 0.06,            // opacity at valleys
 *     opTo:   0.9,             // opacity at summits
 *     cell: 10,                // grid cell size — larger = faster, coarser
 *     over: 1.34,              // overscan multiplier (must be > 1)
 *   });
 *
 * CSS required (add once to your stylesheet):
 *   @keyframes tDrift {
 *     from { transform: translate(calc(var(--dx) * -1), calc(var(--dy) * -1)); }
 *     to   { transform: translate(var(--dx), var(--dy)); }
 *   }
 *   .tDrift {
 *     animation: tDrift linear infinite alternate;
 *     will-change: transform;
 *   }
 *   @media (prefers-reduced-motion: reduce) {
 *     .tDrift { animation: none; }
 *   }
 *
 * The container element should have:
 *   position: relative (or absolute); overflow: hidden;
 *   The SVG uses preserveAspectRatio="xMidYMid slice" so it fills any frame.
 */


// ── 1. Seeded PRNG ────────────────────────────────────────────────────────────
// Mulberry32 — fast, good distribution, fully reproducible from a seed integer.
function mulberry32(a) {
  return function () {
    a |= 0;
    a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}


// ── 2. Seeded 2-D Perlin noise ────────────────────────────────────────────────
// Classic gradient noise. Fully deterministic for a given seed.
function makeNoise(seed) {
  const rnd = mulberry32((seed >>> 0) || 1);
  const perm = new Array(256);
  for (let i = 0; i < 256; i++) perm[i] = i;
  for (let i = 255; i > 0; i--) {
    const j = (rnd() * (i + 1)) | 0;
    const t = perm[i]; perm[i] = perm[j]; perm[j] = t;
  }
  const p = new Uint8Array(512);
  for (let i = 0; i < 512; i++) p[i] = perm[i & 255];

  const fade = t => t * t * t * (t * (t * 6 - 15) + 10);
  const lerp  = (a, b, t) => a + t * (b - a);
  const grad  = (h, x, y) => { const u = (h & 1) ? -x : x, v = (h & 2) ? -y : y; return u + v; };

  return function (x, y) {
    const X = Math.floor(x) & 255, Y = Math.floor(y) & 255;
    x -= Math.floor(x); y -= Math.floor(y);
    const u = fade(x), v = fade(y);
    const aa = p[p[X] + Y],     ba = p[p[X + 1] + Y],
          ab = p[p[X] + Y + 1], bb = p[p[X + 1] + Y + 1];
    return lerp(
      lerp(grad(aa, x,     y), grad(ba, x - 1, y),     u),
      lerp(grad(ab, x, y - 1), grad(bb, x - 1, y - 1), u),
      v
    );
  };
}


// ── 3. Fractional Brownian Motion ─────────────────────────────────────────────
// Layers octaves of noise at increasing frequency / decreasing amplitude.
// This is what gives terrain its natural "rough at large scale, fine at small"
// character — the same technique used in real terrain generation.
function fbm(noise, x, y, oct) {
  let a = 1, f = 1, s = 0, n = 0;
  for (let i = 0; i < oct; i++) {
    s += a * noise(x * f, y * f);
    n += a;
    a *= 0.55;   // amplitude halved each octave (controls roughness)
    f *= 2.0;    // frequency doubled each octave
  }
  return s / n;
}


// ── 4. Colour ramp: valley → summit ──────────────────────────────────────────
// t = 0 (low ground) → deep teal
// t = 1 (summit)     → pale gold
// Matches the quilt reference: yellow ring-centres, green mid-slopes.
function topoRamp(t) {
  const stops = [
    [0,    [62,  143, 115]],   // valley teal
    [0.34, [46,  196, 148]],   // brand green (#2EC494)
    [0.62, [143, 212, 106]],   // lime
    [0.84, [217, 229,  92]],   // yellow-green
    [1,    [242, 233, 107]],   // gold summit
  ];
  for (let i = 1; i < stops.length; i++) {
    if (t <= stops[i][0]) {
      const [ta, ca] = stops[i - 1], [tb, cb] = stops[i];
      const k = (t - ta) / (tb - ta);
      return 'rgb('
        + Math.round(ca[0] + (cb[0] - ca[0]) * k) + ','
        + Math.round(ca[1] + (cb[1] - ca[1]) * k) + ','
        + Math.round(ca[2] + (cb[2] - ca[2]) * k) + ')';
    }
  }
  return 'rgb(242,233,107)';
}


// ── 5. Contour layer (marching squares) ──────────────────────────────────────
// Samples the fbm height field into a grid, then for each iso-elevation level
// runs the marching-squares lookup to find where the contour crosses each cell
// edge. The 16-case lookup table maps the 4-corner above/below bitmask to
// the two edges that carry the contour segment for that cell.
function contourLayer(VW, VH, o) {
  const noise = makeNoise(o.seed || 7);
  const oct   = o.oct  || 4;
  const cell  = o.cell || 8;
  const cols  = Math.max(3, Math.round(VW / cell));
  const rows  = Math.max(3, Math.round(VH / cell));
  const dx    = VW / cols, dy = VH / rows;
  const freq  = o.freq || 3.2;
  const ar    = VH / VW;  // aspect-ratio correction keeps terrain isotropic

  // sample the height field
  const g = new Array(rows + 1);
  let mn = 1e9, mx = -1e9;
  for (let r = 0; r <= rows; r++) {
    g[r] = new Float32Array(cols + 1);
    for (let c = 0; c <= cols; c++) {
      const v = fbm(noise, (c / cols) * freq, (r / rows) * freq * ar, oct);
      g[r][c] = v;
      if (v < mn) mn = v;
      if (v > mx) mx = v;
    }
  }

  const span  = (mx - mn) || 1;
  const levels = o.levels || 16;
  const opLo  = o.opLo  ?? 0.20;
  const opHi  = o.opHi  ?? 0.92;
  const sw    = o.sw    || 1;

  let body = '';

  for (let li = 0; li < levels; li++) {
    const t = (li + 0.5) / levels;
    const L = mn + span * t;
    let d = '';

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const tl = g[r][c], tr = g[r][c + 1],
              br = g[r + 1][c + 1], bl = g[r + 1][c];

        // bitmask: which corners are above the iso-level?
        let id = 0;
        if (tl > L) id |= 8;
        if (tr > L) id |= 4;
        if (br > L) id |= 2;
        if (bl > L) id |= 1;
        if (id === 0 || id === 15) continue; // all below or all above — no contour

        const x = c * dx, y = r * dy;

        // linear interpolation of contour crossing on each edge
        const top = [x + dx * ((L - tl) / (tr - tl)), y];
        const rgt = [x + dx,  y + dy * ((L - tr) / (br - tr))];
        const bot = [x + dx * ((L - bl) / (br - bl)), y + dy];
        const lft = [x,       y + dy * ((L - tl) / (bl - tl))];

        const seg = (a, b) => {
          d += 'M' + a[0].toFixed(1) + ' ' + a[1].toFixed(1)
             + 'L' + b[0].toFixed(1) + ' ' + b[1].toFixed(1);
        };

        // marching-squares 16-case lookup
        switch (id) {
          case  1: seg(lft, bot); break;
          case  2: seg(bot, rgt); break;
          case  3: seg(lft, rgt); break;
          case  4: seg(top, rgt); break;
          case  5: seg(lft, top); seg(bot, rgt); break; // saddle
          case  6: seg(top, bot); break;
          case  7: seg(lft, top); break;
          case  8: seg(top, lft); break;
          case  9: seg(top, bot); break;
          case 10: seg(top, rgt); seg(lft, bot); break; // saddle
          case 11: seg(top, rgt); break;
          case 12: seg(lft, rgt); break;
          case 13: seg(bot, rgt); break;
          case 14: seg(lft, bot); break;
        }
      }
    }

    if (!d) continue;

    // opacity and stroke-width both ramp up toward the summit
    const op = (opLo + (opHi - opLo) * t).toFixed(3);
    const w  = (sw * (0.8 + 0.55 * t)).toFixed(2);

    body += '<path d="' + d + '" fill="none"'
          + ' stroke="' + topoRamp(t) + '"'
          + ' stroke-width="' + w + '"'
          + ' stroke-opacity="' + op + '"'
          + ' stroke-linecap="round" stroke-linejoin="round"/>';
  }

  return body;
}


// ── 6. flowField — public API ─────────────────────────────────────────────────
// Returns an SVG string ready to set as innerHTML on a container element.
// The SVG overscans its frame (controlled by `over`) and two <g> layers
// drift in opposite directions via CSS animation, giving the terrain a slow
// breathing quality without any JS running after first render.
//
// Options:
//   w, h       Frame size in px (match your container)
//   seed       Integer seed — change for a different terrain shape
//   levels     Number of iso-elevation contour lines (12–20 recommended)
//   freq       Terrain spatial frequency (2.0 = wide features, 4.0 = dense)
//   sw         Base stroke width in px
//   two        Boolean — add a second, lighter layer for extra depth
//   dur        CSS animation duration in seconds (longer = slower drift)
//   dx, dy     Max drift offset in px
//   opFrom     Opacity of lowest contours (valleys)
//   opTo       Opacity of highest contours (summits)
//   cell       Grid cell size in px — larger is faster but coarser
//   over       Overscan multiplier (1.3–1.5); must be > 1 for drift to work
function flowField(o) {
  const W    = o.w    || 392;
  const H    = o.h    || 812;
  const seed = o.seed || (((o.phase || 0) * 97 + ((o.w || 0) + (o.h || 0))) | 0) || 7;
  const over = o.over ?? 1.34;
  const VW   = Math.round(W * over);  // overscan canvas width
  const VH   = Math.round(H * over);  // overscan canvas height
  const ox   = -((VW - W) / 2).toFixed(1);  // translate to centre the overscan
  const oy   = -((VH - H) / 2).toFixed(1);
  const sw   = o.sw  || 1;
  const dur  = o.dur || (38 + (seed % 18));
  const dly  = -(seed % dur);
  const maxd = Math.min((VW - W) / 2, (VH - H) / 2) * 0.5;
  const dxp  = Math.min(o.dx || 16, maxd).toFixed(1);
  const dyp  = Math.min(o.dy || 11, maxd).toFixed(1);

  // primary layer
  let layers = '<g class="tDrift" style="'
    + '--dx:' + dxp + 'px;--dy:' + dyp + 'px;'
    + 'animation-duration:' + dur + 's;'
    + 'animation-delay:'   + dly + 's">'
    + contourLayer(VW, VH, {
        seed:   seed,
        levels: o.levels || 16,
        freq:   o.freq   || 3.2,
        sw:     sw,
        cell:   o.cell   || 8,
        opLo:   o.opFrom,
        opHi:   o.opTo,
      })
    + '</g>';

  // optional secondary layer (drifts opposite direction, lower opacity)
  if (o.two) {
    const dur2 = dur * 1.45;
    layers += '<g class="tDrift" style="'
      + '--dx:' + (-dxp) + 'px;--dy:' + (-(dyp * 0.7)).toFixed(1) + 'px;'
      + 'animation-duration:' + dur2 + 's;'
      + 'animation-delay:'   + (dly - 9) + 's;opacity:.45">'
      + contourLayer(VW, VH, {
          seed:   seed + 131,
          levels: Math.round((o.levels || 16) * 0.6),
          freq:   (o.freq || 3.2) * 1.7,
          sw:     sw * 0.8,
          cell:   (o.cell || 8) + 1,
          opLo:   0.14,
          opHi:   0.5,
        })
      + '</g>';
  }

  return '<svg viewBox="0 0 ' + W + ' ' + H + '"'
       + ' preserveAspectRatio="xMidYMid slice"'
       + ' xmlns="http://www.w3.org/2000/svg">'
       + '<g transform="translate(' + ox + ',' + oy + ')">'
       + layers
       + '</g></svg>';
}


// ── Example usage ─────────────────────────────────────────────────────────────
// Uncomment this block in a browser context to try it:
//
// document.querySelectorAll('[data-topo]').forEach(el => {
//   const k = el.dataset.topo;
//   const presets = {
//     hero:    { w:393, h:852, seed:7,  levels:18, freq:3.0, sw:1.05, two:true, dur:64, dx:18, dy:13, opFrom:.06, opTo:.9,  cell:10 },
//     card:    { w:360, h:170, seed:83, levels:12, freq:2.3, sw:1.0,  two:false,dur:46, dx:13, dy:8,  opFrom:.10, opTo:.88, cell:8  },
//     thumb:   { w:120, h:120, seed:101,levels:10, freq:2.0, sw:1.0,  two:false,dur:40, dx:9,  dy:7,  opFrom:.16, opTo:.92, cell:8, over:1.4 },
//   };
//   el.innerHTML = flowField(presets[k] || presets.card);
// });
