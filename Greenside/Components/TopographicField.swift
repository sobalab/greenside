import SwiftUI

// MARK: - Topographic contour engine
//
// A faithful SwiftUI port of `Resources/greenside-topo.js`: seeded Perlin/fBm
// terrain sampled into iso-elevation contour lines via marching squares, with a
// valley→summit colour ramp. Following the JS design, the contours are computed
// **once** (and cached) and rendered into a rasterized layer; only a slow drift
// offset animates, so the terrain "breathes" without a per-frame render loop.

/// One traced iso-elevation contour line and how to stroke it.
private struct TopoContour {
    let path: Path
    let color: Color
    let lineWidth: CGFloat
    let opacity: Double
}

/// Per-layer terrain parameters (mirrors the JS `contourLayer` options).
struct TopoLayerParams: Hashable {
    var levels: Int
    var freq: Double
    var cell: Double
    var sw: Double
    var opLo: Double
    var opHi: Double
    var oct: Int = 4
}

/// A drifting topographic field configuration (mirrors the JS `flowField` presets).
struct TopoConfig {
    var primary: TopoLayerParams
    var over: Double = 1.34
    var dx: Double
    var dy: Double
    var dur: Double
    var two: Bool

    /// The lighter, faster secondary layer used when `two` is set.
    var secondary: TopoLayerParams {
        TopoLayerParams(
            levels: max(6, Int((Double(primary.levels) * 0.6).rounded())),
            freq: primary.freq * 1.7,
            cell: primary.cell + 1,
            sw: primary.sw * 0.8,
            opLo: 0.14,
            opHi: 0.5,
            oct: primary.oct
        )
    }

    /// Full-bleed hero backdrop (Welcome, large green cards).
    static let hero = TopoConfig(
        primary: .init(levels: 18, freq: 3.0, cell: 10, sw: 1.05, opLo: 0.06, opHi: 0.9),
        over: 1.34, dx: 18, dy: 13, dur: 64, two: true
    )
    /// Course card cover.
    static let card = TopoConfig(
        primary: .init(levels: 13, freq: 2.3, cell: 8, sw: 1.0, opLo: 0.10, opHi: 0.9),
        over: 1.34, dx: 13, dy: 8, dur: 46, two: false
    )
    /// Small thumbnail cover.
    static let thumb = TopoConfig(
        primary: .init(levels: 10, freq: 2.0, cell: 8, sw: 1.0, opLo: 0.16, opHi: 0.92),
        over: 1.4, dx: 9, dy: 7, dur: 40, two: false
    )
}

// MARK: - Math (mulberry32 + Perlin + fBm + ramp + marching squares)

private enum TopoEngine {

    /// Mulberry32 seeded PRNG — reproducible per seed (matches the JS bit-ops).
    struct Mulberry32 {
        var a: UInt32
        mutating func next() -> Double {
            a = a &+ 0x6D2B79F5
            var t = (a ^ (a >> 15)) &* (a | 1)
            t = (t &+ ((t ^ (t >> 7)) &* (t | 61))) ^ t
            return Double(t ^ (t >> 14)) / 4294967296.0
        }
    }

    /// Seeded 2-D gradient (Perlin) noise.
    struct Noise {
        let p: [Int]
        init(seed: UInt32) {
            var rnd = Mulberry32(a: seed == 0 ? 1 : seed)
            var perm = Array(0..<256)
            var i = 255
            while i > 0 {
                let j = Int(rnd.next() * Double(i + 1))
                perm.swapAt(i, j)
                i -= 1
            }
            var pp = [Int](repeating: 0, count: 512)
            for k in 0..<512 { pp[k] = perm[k & 255] }
            p = pp
        }
        private func fade(_ t: Double) -> Double { t * t * t * (t * (t * 6 - 15) + 10) }
        private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + t * (b - a) }
        private func grad(_ h: Int, _ x: Double, _ y: Double) -> Double {
            let u = (h & 1) != 0 ? -x : x
            let v = (h & 2) != 0 ? -y : y
            return u + v
        }
        func value(_ x0: Double, _ y0: Double) -> Double {
            let X = Int(floor(x0)) & 255, Y = Int(floor(y0)) & 255
            let x = x0 - floor(x0), y = y0 - floor(y0)
            let u = fade(x), v = fade(y)
            let aa = p[p[X] + Y], ba = p[p[X + 1] + Y]
            let ab = p[p[X] + Y + 1], bb = p[p[X + 1] + Y + 1]
            return lerp(
                lerp(grad(aa, x, y), grad(ba, x - 1, y), u),
                lerp(grad(ab, x, y - 1), grad(bb, x - 1, y - 1), u),
                v
            )
        }
    }

    static func fbm(_ n: Noise, _ x: Double, _ y: Double, _ oct: Int) -> Double {
        var a = 1.0, f = 1.0, s = 0.0, norm = 0.0
        for _ in 0..<oct {
            s += a * n.value(x * f, y * f)
            norm += a
            a *= 0.55
            f *= 2.0
        }
        return s / norm
    }

    /// Valley-teal → brand-green → lime → gold ramp (matches the JS `topoRamp`).
    static func ramp(_ t: Double) -> Color {
        let stops: [(Double, (Double, Double, Double))] = [
            (0.00, (62, 143, 115)),
            (0.34, (46, 196, 148)),
            (0.62, (143, 212, 106)),
            (0.84, (217, 229, 92)),
            (1.00, (242, 233, 107)),
        ]
        for i in 1..<stops.count where t <= stops[i].0 {
            let (ta, ca) = stops[i - 1], (tb, cb) = stops[i]
            let k = (t - ta) / (tb - ta)
            return Color(
                .sRGB,
                red: (ca.0 + (cb.0 - ca.0) * k) / 255,
                green: (ca.1 + (cb.1 - ca.1) * k) / 255,
                blue: (ca.2 + (cb.2 - ca.2) * k) / 255
            )
        }
        return Color(.sRGB, red: 242 / 255, green: 233 / 255, blue: 107 / 255)
    }

    private static var cache: [String: [TopoContour]] = [:]

    /// Marching-squares contours for a terrain, memoized by (size, seed, params).
    static func contours(vw: Double, vh: Double, seed: Int, params p: TopoLayerParams) -> [TopoContour] {
        let key = "\(seed)|\(Int(vw))x\(Int(vh))|\(p.levels)|\(p.freq)|\(p.cell)|\(p.opLo)|\(p.opHi)|\(p.sw)"
        if let hit = cache[key] { return hit }

        let noise = Noise(seed: UInt32(truncatingIfNeeded: seed == 0 ? 7 : seed))
        let cols = max(3, Int((vw / p.cell).rounded()))
        let rows = max(3, Int((vh / p.cell).rounded()))
        let cellW = vw / Double(cols), cellH = vh / Double(rows)
        let ar = vh / vw

        var grid = [[Double]](repeating: [Double](repeating: 0, count: cols + 1), count: rows + 1)
        var mn = Double.greatestFiniteMagnitude, mx = -Double.greatestFiniteMagnitude
        for r in 0...rows {
            for c in 0...cols {
                let v = fbm(noise, Double(c) / Double(cols) * p.freq, Double(r) / Double(rows) * p.freq * ar, p.oct)
                grid[r][c] = v
                mn = min(mn, v); mx = max(mx, v)
            }
        }
        let span = (mx - mn) == 0 ? 1 : (mx - mn)

        var result: [TopoContour] = []
        for li in 0..<p.levels {
            let t = (Double(li) + 0.5) / Double(p.levels)
            let level = mn + span * t
            var path = Path()

            for r in 0..<rows {
                for c in 0..<cols {
                    let tl = grid[r][c], tr = grid[r][c + 1], br = grid[r + 1][c + 1], bl = grid[r + 1][c]
                    var id = 0
                    if tl > level { id |= 8 }
                    if tr > level { id |= 4 }
                    if br > level { id |= 2 }
                    if bl > level { id |= 1 }
                    if id == 0 || id == 15 { continue }

                    let x = Double(c) * cellW, y = Double(r) * cellH
                    let top = CGPoint(x: x + cellW * ((level - tl) / (tr - tl)), y: y)
                    let rgt = CGPoint(x: x + cellW, y: y + cellH * ((level - tr) / (br - tr)))
                    let bot = CGPoint(x: x + cellW * ((level - bl) / (br - bl)), y: y + cellH)
                    let lft = CGPoint(x: x, y: y + cellH * ((level - tl) / (bl - tl)))

                    func seg(_ a: CGPoint, _ b: CGPoint) { path.move(to: a); path.addLine(to: b) }
                    switch id {
                    case 1: seg(lft, bot)
                    case 2: seg(bot, rgt)
                    case 3: seg(lft, rgt)
                    case 4: seg(top, rgt)
                    case 5: seg(lft, top); seg(bot, rgt)
                    case 6: seg(top, bot)
                    case 7: seg(lft, top)
                    case 8: seg(top, lft)
                    case 9: seg(top, bot)
                    case 10: seg(top, rgt); seg(lft, bot)
                    case 11: seg(top, rgt)
                    case 12: seg(lft, rgt)
                    case 13: seg(bot, rgt)
                    case 14: seg(lft, bot)
                    default: break
                    }
                }
            }

            if path.isEmpty { continue }
            let op = p.opLo + (p.opHi - p.opLo) * t
            let w = p.sw * (0.8 + 0.55 * t)
            result.append(TopoContour(path: path, color: ramp(t), lineWidth: w, opacity: op))
        }

        cache[key] = result
        return result
    }
}

// MARK: - Animated field view

/// A drifting topographic contour field. Precomputes contours into a rasterized
/// layer and animates only a slow, autoreversing offset (respecting Reduce
/// Motion). Pass `tint` for a monochrome look (hero cards) or leave it nil for
/// the full valley→summit colour ramp (course covers).
struct AnimatedTopographicField: View {
    var seed: Int
    var config: TopoConfig = .card
    var tint: Color? = nil
    /// When set, scales the whole field toward this peak opacity (subtle mode).
    var maxOpacity: Double? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var t1: CGFloat = 0
    @State private var t2: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LayerCanvas(base: geo.size, seed: seed, params: config.primary, over: config.over,
                            tint: tint, maxOpacity: maxOpacity)
                    .offset(x: config.dx * (t1 * 2 - 1), y: config.dy * (t1 * 2 - 1))

                if config.two {
                    LayerCanvas(base: geo.size, seed: seed &+ 131, params: config.secondary, over: config.over,
                                tint: tint, maxOpacity: maxOpacity.map { $0 * 0.7 })
                        .opacity(0.5)
                        .offset(x: -config.dx * (t2 * 2 - 1), y: -config.dy * 0.7 * (t2 * 2 - 1))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { t1 = 0.5; t2 = 0.5; return }
            withAnimation(.linear(duration: config.dur).repeatForever(autoreverses: true)) { t1 = 1 }
            withAnimation(.linear(duration: config.dur * 1.45).repeatForever(autoreverses: true)) { t2 = 1 }
        }
    }
}

/// One rasterized contour layer, sized to an overscan of its container so the
/// drift offset never exposes an edge.
private struct LayerCanvas: View {
    let base: CGSize
    let seed: Int
    let params: TopoLayerParams
    let over: Double
    let tint: Color?
    let maxOpacity: Double?

    var body: some View {
        let vw = base.width * over
        let vh = base.height * over
        let scale = maxOpacity.map { $0 / params.opHi } ?? 1

        Canvas { context, _ in
            for contour in TopoEngine.contours(vw: vw, vh: vh, seed: seed, params: params) {
                let color = tint ?? contour.color
                context.stroke(
                    contour.path,
                    with: .color(color.opacity(min(1, contour.opacity * scale))),
                    style: StrokeStyle(lineWidth: contour.lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(width: vw, height: vh)
        .drawingGroup()
    }
}

// MARK: - Public wrappers

/// Subtle animated topographic texture for layering over dark green surfaces
/// (hero cards, Welcome). Keeps the previous call sites working, now animated.
struct TopographicLines: View {
    var color: Color = Theme.Palette.lime
    var opacity: Double = 0.16
    var seed: Int = 7
    var config: TopoConfig = .hero

    var body: some View {
        AnimatedTopographicField(seed: seed, config: config, tint: color, maxOpacity: opacity)
    }
}

#Preview("Colour survey") {
    AnimatedTopographicField(seed: 83, config: .card)
        .background(Color(hex: 0x24503A))
        .frame(height: 220)
        .padding()
}

#Preview("Subtle on green") {
    ZStack {
        Theme.Palette.primary
        TopographicLines()
    }
    .frame(height: 220)
    .padding()
}
