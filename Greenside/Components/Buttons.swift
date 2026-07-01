import SwiftUI

/// Full-width filled button on the brand forest green (primary CTA on most screens).
struct GSPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.button)
            .foregroundStyle(Theme.Palette.onDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(enabled ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.Palette.inkTertiary))
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Full-width button filled with the signature brand gradient.
struct GSGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.button)
            .foregroundStyle(Theme.Palette.onDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Theme.brandGradient,
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Full-width light button (white surface, dark green label) — e.g. "Get started".
struct GSLightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.button)
            .foregroundStyle(Theme.Palette.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Theme.Palette.surface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
