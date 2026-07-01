import SwiftUI

/// The very first screen the app opens on. A calm, editorial Birdie landing on
/// the sage `ground`: a light clay ContourHero panel breathes up top, a huge
/// Funnel Display wordmark and tagline lead the middle, and the two onboarding
/// CTAs are anchored near the bottom above a row of trust stats. Both buttons
/// advance the app into the sign-in phase.
struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Theme.Palette.ground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Airy clay texture panel up top — light and organic.
                ContourHero(tint: Theme.Palette.clay, seed: 21, maxOpacity: 0.5)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Theme.Palette.charcoal.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 14, y: 6)

                Spacer(minLength: 0)

                // Emblem + wordmark + tagline
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Palette.charcoal)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Greenside")
                            .font(.display(60, .bold))
                            .foregroundStyle(Theme.Palette.charcoal)

                        Text("Find an open tee time, read the green, and lock in your round in under a minute.")
                            .font(.body(17, .regular))
                            .foregroundStyle(Theme.Palette.muted)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: Theme.Spacing.xxxl)

                // Primary CTAs — the one loud accent is "Get started".
                VStack(spacing: Theme.Spacing.sm) {
                    PillButton(title: "Get started", style: .volt, fill: true) {
                        appState.phase = .signIn
                    }

                    PillButton(title: "I already have an account", style: .ink, fill: true) {
                        appState.phase = .signIn
                    }
                }

                Spacer()
                    .frame(height: Theme.Spacing.xl)

                // Trust stats
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    WelcomeStat(label: "500+ courses")
                    WelcomeStat(label: "Live availability")
                    WelcomeStat(label: "Instant booking")
                }

                Spacer()
                    .frame(height: Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.screenPadding)
        }
    }
}

/// One of the three tiny trust indicators in the footer row: a small charcoal
/// checkmark beside a short muted label, evenly distributed across the row.
private struct WelcomeStat: View {
    let label: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxs) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Palette.charcoal)
                .accessibilityHidden(true)

            Text(label)
                .font(.body(13, .medium))
                .foregroundStyle(Theme.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    WelcomeView()
        .environment(AppState())
}
