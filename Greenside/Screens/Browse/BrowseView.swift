import SwiftUI

/// The **Browse** tab root: a searchable, filterable catalogue of courses.
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
        if isLoading && results.isEmpty {
            return "Finding the best rounds near you"
        }
        let count = results.count
        return count == 1 ? "1 course available" : "\(count) courses available"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg, pinnedViews: []) {
                    header

                    BrowseSearchField(query: $query)
                        .padding(.horizontal, Theme.screenPadding)

                    filterChips

                    resultsSection
                        .padding(.horizontal, Theme.screenPadding)
                }
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, Theme.Spacing.xxxl)
            }
            .background(Theme.Palette.background.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Course.self) { CourseDetailView(course: $0) }
            .task(id: reloadKey) {
                isLoading = true
                results = await appState.service.searchCourses(query: query, filters: selected)
                isLoading = false
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            EyebrowText("Explore")
            Text("Browse courses")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Palette.ink)
            Text(resultCountLabel)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: results.count)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Filters

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(CourseFilter.allCases) { filter in
                    GSChip(
                        title: filter.rawValue,
                        isSelected: selected.contains(filter)
                    ) {
                        toggle(filter)
                    }
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.vertical, 2)
        }
    }

    private func toggle(_ filter: CourseFilter) {
        Haptics.selection()
        if selected.contains(filter) {
            selected.remove(filter)
        } else {
            selected.insert(filter)
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsSection: some View {
        if isLoading && results.isEmpty {
            BrowseLoadingState()
        } else if results.isEmpty {
            BrowseEmptyState(hasQuery: !query.isEmpty || !selected.isEmpty)
        } else {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(results) { course in
                    NavigationLink(value: course) {
                        BrowseCourseCard(course: course)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Search field

/// A rounded, hairline-bordered search pill with a leading magnifier and an
/// inline clear button.
private struct BrowseSearchField: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.inkTertiary)

            TextField("", text: $query, prompt: placeholder)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Palette.inkTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .background(Theme.Palette.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.Palette.hairline, lineWidth: 1))
        .animation(.snappy, value: query.isEmpty)
    }

    private var placeholder: Text {
        Text("Search courses or cities")
            .font(Theme.Typography.body)
            .foregroundColor(Theme.Palette.inkTertiary)
    }
}

// MARK: - Result card

/// A full-width course card: hero image with a price tag and up to two course
/// tags, then a name / location row with an inline rating.
private struct BrowseCourseCard: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            CourseImage(course: course)
                .frame(maxWidth: .infinity)
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    PriceTag(amount: course.greenFee)
                        .padding(Theme.Spacing.sm)
                }
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(course.tags.prefix(2)) { tag in
                            // White-on-dark chip so tags stay legible over the
                            // course imagery (GSTag's tint is for light cards).
                            Text(tag.rawValue)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.black.opacity(0.35), in: Capsule())
                        }
                    }
                    .padding(Theme.Spacing.sm)
                }

            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(1)
                    Text(course.location)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: Theme.Spacing.xs)

                RatingLabel(
                    rating: course.rating,
                    trailing: "\(course.slotsAvailableToday) slots"
                )
                .fixedSize()
            }
            .padding(.horizontal, Theme.Spacing.xxs)
            .padding(.bottom, Theme.Spacing.xxs)
        }
        .gsCard(padding: Theme.Spacing.sm)
    }
}

// MARK: - Loading & empty states

/// Centered spinner shown on first load before any results arrive.
private struct BrowseLoadingState: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Theme.Palette.primary)
            Text("Searching courses")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxxl * 2)
    }
}

/// Muted empty state shown when a search / filter combination has no matches.
private struct BrowseEmptyState: View {
    let hasQuery: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Theme.Palette.inkTertiary)
                .frame(width: 64, height: 64)
                .background(Theme.Palette.surfaceMuted, in: Circle())
                .padding(.bottom, Theme.Spacing.xxs)

            Text("No courses match")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Palette.ink)

            Text(hasQuery
                 ? "Try a different search or clear a few filters to see more tee times."
                 : "We couldn’t find any courses right now. Check back in a moment.")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxxl)
    }
}

#Preview {
    BrowseView()
        .environment(AppState())
}
