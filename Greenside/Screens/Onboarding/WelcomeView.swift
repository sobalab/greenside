import SwiftUI

/// The very first screen the app opens on. A full-bleed topographic brand
/// backdrop with the Greenside emblem, wordmark, and tagline pinned toward the
/// lower-middle, and the two onboarding CTAs anchored near the bottom. Both
/// buttons advance the app into the sign-in phase.
struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            TopographicBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                // Emblem + wordmark + tagline
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 54))
                        .foregroundStyle(Theme.Palette.lime)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Greenside")
                            .font(Theme.Typography.welcome)
                            .foregroundStyle(Theme.Palette.onDark)

                        Text("Find an open tee time, read the green, and lock in your round in under a minute.")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Palette.onDarkSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
                    .frame(height: Theme.Spacing.xxxl)

                // Primary CTAs
                VStack(spacing: Theme.Spacing.sm) {
                    Button("Get started") {
                        appState.phase = .signIn
                    }
                    .buttonStyle(GSLightButtonStyle())

                    Button("I already have an account") {
                        appState.phase = .signIn
                    }
                    .buttonStyle(GSGradientButtonStyle())
                }

                Spacer()
                    .frame(height: Theme.Spacing.xl)

                // Trust stats
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    WelcomeStat(label: "500+ courses")
                    WelcomeStat(label: "Live availability")
                    WelcomeStat(label: "Instant booking")
                }
                .padding(.bottom, Theme.Spacing.xs)

                Spacer()
                    .frame(height: Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.screenPadding)
        }
    }
}

/// One of the three tiny trust indicators in the footer row: a lime checkmark
/// above (or beside) a short label, evenly distributed across the row.
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    WelcomeView()
        .environment(AppState())
}
