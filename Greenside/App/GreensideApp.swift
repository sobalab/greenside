import SwiftUI

@main
struct GreensideApp: App {
    @State private var appState = AppState()

    init() {
        FontRegistration.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .tint(Theme.Palette.primary)
        }
    }
}
