import SwiftUI

/// The four-tab shell that matches the design's tab bar: Home, Browse, Book, Profile.
///
/// Tab contents are placeholders for now — real screens are built next, in order.
/// The structure, shared state wiring, and tab bar are in place so the app runs.
struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            ScreenPlaceholder(name: "Home", systemImage: "house.fill")
                .tabItem { Label("Home", systemImage: "house") }

            ScreenPlaceholder(name: "Browse", systemImage: "magnifyingglass")
                .tabItem { Label("Browse", systemImage: "magnifyingglass") }

            // Book tab hosts the 3-step wizard driven by the shared BookingViewModel.
            NavigationStack(path: bookingPath) {
                ScreenPlaceholder(name: "Book", systemImage: "calendar")
            }
            .tabItem { Label("Book", systemImage: "calendar") }

            ScreenPlaceholder(name: "Profile", systemImage: "person.fill")
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }

    /// Binding into the shared booking view model's navigation path.
    private var bookingPath: Binding<[BookingRoute]> {
        Binding(
            get: { appState.booking.path },
            set: { appState.booking.path = $0 }
        )
    }
}

/// Placeholder tab body shown until the real screen is implemented.
struct ScreenPlaceholder: View {
    let name: String
    let systemImage: String

    var body: some View {
        ZStack {
            Theme.Palette.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Theme.Palette.primary)
                Text(name)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Coming next")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
