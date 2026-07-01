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

// `TopographicLines` (the contour texture layered over dark surfaces) now lives
// in `TopographicField.swift`, where it renders the animated marching-squares
// terrain ported from `Resources/greenside-topo.js`.

#Preview {
    TopographicBackground().ignoresSafeArea()
}
