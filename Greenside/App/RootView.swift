import SwiftUI

/// Switches between the onboarding phases and the main tab experience.
struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.phase {
            case .welcome:
                WelcomeView()
            case .signIn:
                SignInView()
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.phase)
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
