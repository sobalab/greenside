import SwiftUI

/// Springy press-scale for buttons and tappable cards. Confident, not bouncy.
struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.34, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

/// A slowly-drifting version of the brand gradient — the "living" texture that
/// marks prime / limited-availability tee times. Keeps the green identity while
/// giving those rows a breathing quality (respects Reduce Motion).
struct BrandGradientDrift: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var t: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height, r = max(w, h)
            ZStack {
                Theme.Palette.gradientStops[0]
                blob(Theme.Palette.gradientStops[1], r * 1.15)
                    .position(x: lerp(w * 0.12, w * 0.55, t), y: lerp(h * 0.2, h * 0.7, t))
                blob(Theme.Palette.gradientStops[2], r * 0.95)
                    .position(x: lerp(w * 0.9, w * 0.5, t), y: lerp(h * 0.8, h * 0.3, t))
                blob(Theme.Palette.gradientStops[3], r * 0.8)
                    .position(x: lerp(w * 0.65, w * 0.95, 1 - t), y: lerp(h * 1.0, h * 0.5, t))
            }
            .frame(width: w, height: h)
            .blur(radius: r * 0.22)
            .clipped()
        }
        .onAppear {
            guard !reduceMotion else { t = 0.5; return }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { t = 1 }
        }
    }

    private func blob(_ color: Color, _ size: CGFloat) -> some View {
        Circle().fill(color).frame(width: size, height: size)
    }
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
}

/// A circular progress ring (loyalty tier). Big number lives in the centre.
struct ProgressRing<Center: View>: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var trackColor: Color = Theme.Palette.surfaceMuted
    var tint: AnyShapeStyle = AnyShapeStyle(Theme.brandGradient)
    @ViewBuilder var center: () -> Center

    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: max(0.001, animated))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            center()
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.15)) {
                animated = min(max(progress, 0), 1)
            }
        }
    }
}
