import SwiftUI

/// The four-tab shell: Home, Browse, Book, Profile. Uses a custom solid tab bar
/// (not the system "liquid glass" bar) pinned to the bottom safe area, with a
/// springy select animation. All four tab roots stay mounted so each keeps its
/// own navigation + scroll state when you switch away and back.
struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        ZStack {
            tab(.home) { HomeView() }
            tab(.browse) { BrowseView() }
            tab(.book) { BookRootView() }
            tab(.profile) { ProfileView() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showTabBar {
                GreensideTabBar(selection: $appState.selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: showTabBar)
    }

    /// Hide the bar for the whole focused booking flow (from picking a tee time
    /// through confirmation) so it never collides with the flow's own bottom
    /// action bars. The Book landing (no course chosen yet) keeps the bar.
    private var showTabBar: Bool {
        !(appState.selectedTab == .book && appState.booking.course != nil)
    }

    @ViewBuilder
    private func tab<Content: View>(_ tab: AppTab, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .opacity(appState.selectedTab == tab ? 1 : 0)
            .allowsHitTesting(appState.selectedTab == tab)
            .zIndex(appState.selectedTab == tab ? 1 : 0)
    }
}

// MARK: - Custom tab bar

/// A solid, editorial bottom tab bar. The selected item reads in brand green
/// with a filled glyph and a subtle lift; the glyph bounces on selection.
private struct GreensideTabBar: View {
    @Binding var selection: AppTab

    private let items: [TabBarItem] = [
        TabBarItem(tab: .home, icon: "house", selectedIcon: "house.fill", label: "Home"),
        TabBarItem(tab: .browse, icon: "magnifyingglass", selectedIcon: "magnifyingglass", label: "Browse"),
        TabBarItem(tab: .book, icon: "calendar", selectedIcon: "calendar", label: "Book"),
        TabBarItem(tab: .profile, icon: "person", selectedIcon: "person.fill", label: "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                TabBarButton(item: item, isSelected: selection == item.tab) {
                    guard selection != item.tab else { return }
                    Haptics.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selection = item.tab
                    }
                }
            }
        }
        .padding(.top, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.xs)
        .background(
            Theme.Palette.surface
                .overlay(Theme.Palette.hairline.frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct TabBarItem: Identifiable {
    let tab: AppTab
    let icon: String
    let selectedIcon: String
    let label: String
    var id: AppTab { tab }
}

private struct TabBarButton: View {
    let item: TabBarItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? item.selectedIcon : item.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)
                    .scaleEffect(isSelected ? 1.08 : 1)
                    .frame(height: 26)
                Text(item.label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Theme.Palette.primary : Theme.Palette.inkTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
