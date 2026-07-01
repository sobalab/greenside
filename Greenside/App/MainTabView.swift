import SwiftUI

/// The four-tab shell: Home, Browse, Book, Profile. Each tab hosts a
/// self-contained screen — the tab-root screens own their own navigation, and
/// the Book tab hosts the 3-step booking wizard. The selected tab is driven by
/// `AppState` so screens can switch tabs programmatically (e.g. Home's
/// "Browse courses" action, or "Book" from a course detail screen).
struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)

            BrowseView()
                .tabItem { Label("Browse", systemImage: "magnifyingglass") }
                .tag(AppTab.browse)

            BookRootView()
                .tabItem { Label("Book", systemImage: "calendar") }
                .tag(AppTab.book)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(AppTab.profile)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
