import SwiftUI

@main
struct GreensideApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .tint(Theme.Palette.primary)
        }
    }
}
