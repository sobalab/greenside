import SwiftUI

/// Springy press-scale for the two button primitives.
struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.93
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.34, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A perfect-circle icon button — back chevron, close X, history clock, an
/// up-right "open" arrow. Thin SF Symbol on a soft surface.
struct CircleIconButton: View {
    let systemName: String
    var size: CGFloat = 46
    var style: Style = .frosted
    var action: () -> Void

    enum Style { case frosted, ink, volt, paper }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: .regular))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Theme.Palette.charcoal.opacity(style == .frosted ? 0.06 : 0), lineWidth: 1)
                )
        }
        .buttonStyle(PressScaleStyle())
    }

    private var foreground: Color {
        switch style {
        case .frosted, .paper: return Theme.Palette.charcoal
        case .ink:  return Theme.Palette.paper
        case .volt: return Theme.Palette.charcoal
        }
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .frosted: Rectangle().fill(.ultraThinMaterial)
        case .ink:     Rectangle().fill(Theme.Palette.charcoal)
        case .volt:    Rectangle().fill(Theme.Palette.volt)
        case .paper:   Rectangle().fill(Theme.Palette.paper)
        }
    }
}

/// A pill text button — "Book 10:24", "Confirm · $54". The `.volt` style is the
/// app's single loud accent; use it sparingly.
struct PillButton: View {
    let title: String
    var icon: String? = nil
    var style: Style = .volt
    var fill: Bool = false
    var action: () -> Void

    enum Style { case volt, ink, frosted, paper }

    var body: some View {
        Button {
            Haptics.impact()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                }
                Text(title).font(.body(16, .semibold))
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 22)
            .padding(.vertical, 15)
            .frame(maxWidth: fill ? .infinity : nil)
            .background(background)
            .clipShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
    }

    private var foreground: Color {
        switch style {
        case .volt, .paper, .frosted: return Theme.Palette.charcoal
        case .ink: return Theme.Palette.paper
        }
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .volt:    Theme.Palette.volt
        case .ink:     Theme.Palette.charcoal
        case .paper:   Theme.Palette.paper
        case .frosted: Rectangle().fill(.ultraThinMaterial)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "chevron.left", style: .frosted) {}
            CircleIconButton(systemName: "clock.arrow.circlepath", style: .paper) {}
            CircleIconButton(systemName: "arrow.up.right", style: .ink) {}
            CircleIconButton(systemName: "sparkles", style: .volt) {}
        }
        PillButton(title: "Book 10:24", icon: "flag.fill") {}
        PillButton(title: "Confirm · $54", fill: true) {}
        PillButton(title: "Walk", style: .ink) {}
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Palette.ground)
}
