import SwiftUI

/// Standard white card container used throughout the app.
struct GSCardModifier: ViewModifier {
    var padding: CGFloat = Theme.Spacing.md
    var cornerRadius: CGFloat = Theme.Radius.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                Theme.Palette.surface,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .shadow(
                color: Theme.Shadow.card.color,
                radius: Theme.Shadow.card.radius,
                x: 0,
                y: Theme.Shadow.card.y
            )
    }
}

extension View {
    /// Wrap content in the standard Greenside card surface.
    func gsCard(padding: CGFloat = Theme.Spacing.md,
               cornerRadius: CGFloat = Theme.Radius.md) -> some View {
        modifier(GSCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}
