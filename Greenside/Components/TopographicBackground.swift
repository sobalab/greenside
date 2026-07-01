import SwiftUI

/// The dark, topographic-map background used on the Welcome screen and behind
/// hero surfaces. Renders the brand forest gradient with procedurally-drawn
/// contour lines and a soft central glow, approximating the Figma artwork
/// without shipping a bitmap asset.
struct TopographicBackground: View {
    /// Contour line color.
    var line: Color = Theme.Palette.lime
    /// Overall line opacity.
    var lineOpacity: Double = 0.16

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Theme.Palette.primaryDeep,
                    Theme.Palette.primary,
                    Color(hex: 0x24593F),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            TopographicLines(color: line, opacity: lineOpacity)
            RadialGradient(
                colors: [Theme.Palette.lime.opacity(0.16), .clear],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 420
            )
            .blendMode(.screen)
        }
    }
}

/// Just the procedural contour lines, for layering over an existing dark
/// surface (e.g. the "Your next round" hero card or an image placeholder).
struct TopographicLines: View {
    var color: Color = Theme.Palette.lime
    var opacity: Double = 0.16

    var body: some View {
        Canvas { context, size in
            let centers: [CGPoint] = [
                CGPoint(x: size.width * 0.30, y: size.height * 0.34),
                CGPoint(x: size.width * 0.82, y: size.height * 0.16),
                CGPoint(x: size.width * 0.68, y: size.height * 0.72),
                CGPoint(x: size.width * 0.08, y: size.height * 0.82),
            ]
            let maxDim = max(size.width, size.height)
            for (i, center) in centers.enumerated() {
                for r in 1...9 {
                    let baseRadius = maxDim * 0.06 * Double(r) + Double(i) * 8
                    let path = Self.wobblyRing(
                        center: center,
                        radius: baseRadius,
                        amplitude: baseRadius * 0.10,
                        lobes: 5 + i,
                        phase: Double(i) * 1.3 + Double(r) * 0.35
                    )
                    context.stroke(path, with: .color(color.opacity(opacity)), lineWidth: 1.1)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// A closed circle whose radius is perturbed by a sine wave, giving the
    /// organic look of a topographic contour ring.
    private static func wobblyRing(center: CGPoint, radius: Double, amplitude: Double, lobes: Int, phase: Double) -> Path {
        var path = Path()
        let steps = 120
        for s in 0...steps {
            let t = Double(s) / Double(steps) * 2 * .pi
            let rr = radius + amplitude * sin(Double(lobes) * t + phase)
            let point = CGPoint(x: center.x + rr * cos(t), y: center.y + rr * sin(t))
            if s == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    TopographicBackground().ignoresSafeArea()
}
