import SwiftUI

/// The very first screen the app opens on. A full-bleed dark-green topographic
/// brand backdrop with the Greenside emblem and huge editorial wordmark pinned
/// toward the lower-middle, the tagline beneath, and the two onboarding CTAs
/// anchored near the bottom above a row of trust stats. Everything makes a
/// confident, staggered spring entrance. Both buttons advance the app into the
/// sign-in phase.
struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    var body: some View {
        ZStack {
            TopographicBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                // Emblem + huge wordmark
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 54))
                        .foregroundStyle(Theme.Palette.lime)
                        .accessibilityHidden(true)

                    Text("Greenside")
                        .font(Theme.Typography.display(58, .bold))
                        .foregroundStyle(Theme.Palette.onDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .entrance(appeared, delay: 0, reduceMotion: reduceMotion)

                // Tagline
                Text("Find an open tee time, read the green, and lock in your round in under a minute.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.onDarkSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Theme.Spacing.md)
                    .entrance(appeared, delay: 0.08, reduceMotion: reduceMotion)

                Spacer()
                    .frame(height: Theme.Spacing.xxxl)

                // Primary CTAs
                VStack(spacing: Theme.Spacing.sm) {
                    Button("Get started") {
                        Haptics.tap()
                        appState.phase = .signIn
                    }
                    .buttonStyle(GSLightButtonStyle())

                    Button("I already have an account") {
                        Haptics.tap()
                        appState.phase = .signIn
                    }
                    .buttonStyle(GSGradientButtonStyle())
                }
                .entrance(appeared, delay: 0.16, reduceMotion: reduceMotion)

                Spacer()
                    .frame(height: Theme.Spacing.xl)

                // Trust stats
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    WelcomeStat(label: "500+ courses")
                    WelcomeStat(label: "Live availability")
                    WelcomeStat(label: "Instant booking")
                }
                .padding(.bottom, Theme.Spacing.xs)
                .entrance(appeared, delay: 0.24, reduceMotion: reduceMotion)

                Spacer()
                    .frame(height: Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.screenPadding)
        }
        .onAppear { appeared = true }
    }
}

/// One of the three tiny trust indicators in the footer row: a lime checkmark
/// beside a short label, evenly distributed across the row.
private struct WelcomeStat: View {
    let label: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxs) {
            Image(systemName: "checkmark")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.lime)
                .accessibilityHidden(true)

            Text(label)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.onDarkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A staggered fade + slide-up entrance for a single block. The offset is
/// dropped under Reduce Motion so only the fade remains.
private struct EntranceEffect: ViewModifier {
    let appeared: Bool
    let delay: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : (reduceMotion ? 0 : 16))
            .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(delay), value: appeared)
    }
}

private extension View {
    func entrance(_ appeared: Bool, delay: Double, reduceMotion: Bool) -> some View {
        modifier(EntranceEffect(appeared: appeared, delay: delay, reduceMotion: reduceMotion))
    }
}

#Preview {
    WelcomeView()
        .environment(AppState())
}
