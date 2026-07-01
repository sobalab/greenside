import SwiftUI

/// Discover (home) — the Birdie redesign. Sage ground, an oversized Funnel
/// Display heading, the floating SmartSearchPill, a featured course over the
/// ContourHero texture, and a scroll of nearby courses. Owns its NavigationStack.
struct DiscoverView: View {
    @Environment(AppState.self) private var appState

    @State private var profile: UserProfile?
    @State private var courses: [Course] = []
    @State private var selected: Course?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                    heading

                    SmartSearchPill(query: searchSummary,
                                    onTap: { appState.selectedTab = .browse },
                                    onSparkles: { appState.selectedTab = .browse })

                    if courses.isEmpty {
                        loading
                    } else {
                        FeaturedCourseCard(
                            course: courses[0],
                            onOpen: { selected = courses[0] },
                            onBook: { book(courses[0]) }
                        )

                        nearbyHeader

                        LazyVStack(spacing: 12) {
                            ForEach(courses.dropFirst()) { course in
                                DiscoverCourseCard(course: course) { selected = course }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 44)
                .navigationDestination(item: $selected) { course in
                    CourseDetailView(course: course)
                }
            }
            .background(Theme.Palette.ground.ignoresSafeArea())
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                profile = await appState.service.currentUser()
                courses = await appState.service.fetchRecommended()
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Text(todayString)
                .font(.body(12, .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.muted)
            Spacer()
            CircleIconButton(systemName: "clock.arrow.circlepath", style: .paper) {
                appState.selectedTab = .profile
            }
        }
    }

    // MARK: - Heading

    private var heading: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Good \(partOfDay),")
                .font(.display(30, .medium))
                .foregroundStyle(Theme.Palette.muted)
            Text("Find your round.")
                .font(.display(52, .bold))
                .foregroundStyle(Theme.Palette.charcoal)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.top, -2)
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    // MARK: - Nearby header

    private var nearbyHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Nearby")
                .font(.display(24, .bold))
                .foregroundStyle(Theme.Palette.charcoal)
            Spacer()
            Text("\(courses.count) courses")
                .font(.body(13, .medium))
                .foregroundStyle(Theme.Palette.muted)
        }
        .padding(.top, 4)
    }

    // MARK: - Loading

    private var loading: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Theme.Palette.charcoal)
            Text("Finding rounds near you")
                .font(.body(13, .medium))
                .foregroundStyle(Theme.Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Actions

    private func book(_ course: Course) {
        appState.booking.start(course: course)
        appState.selectedTab = .book
    }

    // MARK: - Copy

    private var firstName: String { profile?.firstName ?? "Golfer" }

    private var searchSummary: String { "Today · 2 players · morning · under $200" }

    private var partOfDay: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: return "morning"
        case ..<17: return "afternoon"
        default: return "evening"
        }
    }

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        return f.string(from: Date()).uppercased()
    }
}

#Preview {
    DiscoverView()
        .environment(AppState())
}
