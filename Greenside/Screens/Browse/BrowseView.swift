import SwiftUI

/// The **Browse** tab root, restyled into the Birdie design language: a big
/// editorial header over sage ground, a frosted-paper search pill, a row of
/// rounded filter chips, and a live list of `DiscoverCourseCard`s.
///
/// Owns its own `NavigationStack` and pushes `CourseDetailView` for any tapped
/// course. Results are driven live by `searchCourses(query:filters:)` — the
/// combination of the search text and the active filter chips forms a reload
/// key that re-runs the query whenever either changes.
struct BrowseView: View {
    @Environment(AppState.self) private var appState

    @State private var query: String = ""
    @State private var selected: Set<CourseFilter> = []
    @State private var results: [Course] = []
    @State private var isLoading: Bool = false
    @State private var selectedCourse: Course?

    /// Encodes the current query + filter selection so `.task(id:)` re-fires
    /// on any change to either input.
    private var reloadKey: String {
        let filterKey = selected
            .map(\.id)
            .sorted()
            .joined(separator: ",")
        return "\(query.lowercased())|\(filterKey)"
    }

    private var resultCountLabel: String {
        let count = results.count
        return count == 1 ? "1 course available" : "\(count) courses available"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header

                    BrowseSearchField(query: $query)
                        .padding(.horizontal, 20)

                    filterChips

                    resultsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                }
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
            .background(Theme.Palette.ground.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedCourse) { course in
                CourseDetailView(course: course)
            }
            .task(id: reloadKey) {
                isLoading = true
                results = await appState.service.searchCourses(query: query, filters: selected)
                isLoading = false
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EXPLORE")
                .font(.body(12, .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.muted)

            Text("Browse courses")
                .font(.display(38, .bold))
                .foregroundStyle(Theme.Palette.charcoal)
                .fixedSize(horizontal: false, vertical: true)

            Text(resultCountLabel)
                .font(.body(13, .medium))
                .foregroundStyle(Theme.Palette.muted)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: results.count)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Filters

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CourseFilter.allCases) { filter in
                    BrowseFilterChip(
                        title: filter.rawValue,
                        isSelected: selected.contains(filter)
                    ) {
                        toggle(filter)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }

    private func toggle(_ filter: CourseFilter) {
        Haptics.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if selected.contains(filter) {
                selected.remove(filter)
            } else {
                selected.insert(filter)
            }
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsSection: some View {
        if isLoading && results.isEmpty {
            BrowseLoadingState()
        } else if results.isEmpty {
            BrowseEmptyState()
        } else {
            LazyVStack(spacing: 12) {
                ForEach(results) { course in
                    DiscoverCourseCard(course: course) {
                        selectedCourse = course
                    }
                }
            }
        }
    }
}

// MARK: - Search field

/// A rounded, paper search pill with a leading magnifier and an inline clear
/// button — a real editable field styled to hover on the sage ground.
private struct BrowseSearchField: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Palette.muted)

            TextField("", text: $query, prompt: placeholder)
                .font(.body(16, .regular))
                .foregroundStyle(Theme.Palette.charcoal)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    Haptics.tap()
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.Palette.muted)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(Theme.Palette.paper, in: Capsule())
        .overlay(Capsule().stroke(Theme.Palette.mist, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: query.isEmpty)
    }

    private var placeholder: Text {
        Text("Search courses or cities")
            .foregroundColor(Theme.Palette.muted)
    }
}

// MARK: - Filter chip

/// A springy filter chip: charcoal fill + paper text when selected, otherwise a
/// paper fill with a mist hairline.
private struct BrowseFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body(14, .medium))
                .foregroundStyle(isSelected ? Theme.Palette.paper : Theme.Palette.charcoal)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background {
                    if isSelected {
                        Capsule().fill(Theme.Palette.charcoal)
                    } else {
                        Capsule()
                            .fill(Theme.Palette.paper)
                            .overlay(Capsule().stroke(Theme.Palette.mist, lineWidth: 1))
                    }
                }
        }
        .buttonStyle(PressScaleStyle())
    }
}

// MARK: - Loading & empty states

/// Centered spinner shown on first load before any results arrive.
private struct BrowseLoadingState: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.Palette.charcoal)
            Text("Finding the best rounds near you")
                .font(.body(13, .medium))
                .foregroundStyle(Theme.Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

/// Muted empty state shown when a search / filter combination has no matches.
private struct BrowseEmptyState: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Theme.Palette.muted)
                .frame(width: 72, height: 72)
                .background(Theme.Palette.mist, in: Circle())

            Text("No courses match")
                .font(.display(24, .bold))
                .foregroundStyle(Theme.Palette.charcoal)

            Text("Try a different search or clear a few filters to see more tee times.")
                .font(.body(14, .regular))
                .foregroundStyle(Theme.Palette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}

#Preview {
    BrowseView()
        .environment(AppState())
}
