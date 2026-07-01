import SwiftUI

/// The living dawn gradient — soft, slowly-breathing peach → coral → pink → sky
/// blobs. Reserved for prime / limited-availability status; never decoration.
/// Drifts on a slow autoreversing loop (respects Reduce Motion).
struct DawnGradient: View {
    var animated: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var t: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let r = max(w, h)
            ZStack {
                Theme.Palette.dawnStops[1]
                blob(Theme.Palette.dawnStops[0], r * 1.15)
                    .position(x: lerp(w * 0.12, w * 0.5, t), y: lerp(h * 0.15, h * 0.55, t))
                blob(Theme.Palette.dawnStops[2], r * 1.0)
                    .position(x: lerp(w * 0.9, w * 0.55, t), y: lerp(h * 0.75, h * 0.3, t))
                blob(Theme.Palette.dawnStops[3], r * 0.95)
                    .position(x: lerp(w * 0.7, w * 0.95, 1 - t), y: lerp(h * 1.0, h * 0.5, t))
                blob(Theme.Palette.dawnStops[0], r * 0.8)
                    .position(x: lerp(w * 0.3, w * 0.05, t), y: lerp(h * 0.9, h * 0.6, 1 - t))
            }
            .frame(width: w, height: h)
            .blur(radius: r * 0.22)
            .clipped()
        }
        .onAppear {
            guard animated, !reduceMotion else { t = 0.5; return }
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                t = 1
            }
        }
    }

    private func blob(_ color: Color, _ size: CGFloat) -> some View {
        Circle().fill(color).frame(width: size, height: size)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
}

/// A soft organic contour texture behind course headers — the one texture that
/// offsets the otherwise-flat UI. Reuses the marching-squares topographic engine
/// tinted `clay`, drifting lazily.
struct ContourHero: View {
    var tint: Color = Theme.Palette.clay
    var seed: Int = 21
    var maxOpacity: Double = 0.6

    var body: some View {
        AnimatedTopographicField(seed: seed, config: .hero, tint: tint, maxOpacity: maxOpacity)
    }
}

/// A process-stable seed from a string (for per-course texture variety).
func birdieSeed(_ string: String) -> Int {
    var hash = 5381
    for byte in string.utf8 { hash = (hash &* 33) &+ Int(byte) }
    return abs(hash) % 100000
}

#Preview("Dawn") {
    DawnGradient()
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding()
        .frame(maxHeight: .infinity)
        .background(Theme.Palette.ground)
}
