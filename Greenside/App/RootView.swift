import SwiftUI

/// Switches between the onboarding phases and the main tab experience.
struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        switch appState.phase {
        case .welcome:
            // Real WelcomeView is built next; placeholder keeps the app runnable.
            OnboardingPlaceholder(title: "Welcome", phase: .main)
        case .signIn:
            OnboardingPlaceholder(title: "Sign in", phase: .main)
        case .main:
            MainTabView()
        }
    }
}

/// Temporary onboarding stand-in; replaced by WelcomeView / SignInView.
private struct OnboardingPlaceholder: View {
    @Environment(AppState.self) private var appState
    let title: String
    let phase: AppPhase

    var body: some View {
        ZStack {
            Theme.Palette.primary.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.lg) {
                Text(title)
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Palette.onDark)
                Button("Continue") { appState.phase = phase }
                    .buttonStyle(GSLightButtonStyle())
                    .padding(.horizontal, Theme.Spacing.xxxl)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
