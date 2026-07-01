import SwiftUI

/// Home tab root. Greets the golfer, surfaces their next round on a brand-green
/// hero card, offers the two primary quick actions, and rails a set of
/// recommended courses. Owns its own `NavigationStack` and pushes
/// `CourseDetailView` for any tapped course.
struct HomeView: View {
    @Environment(AppState.self) private var appState

    @State private var profile: UserProfile?
    @State private var next: Booking?
    @State private var recommended: [Course] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    header
                    heroSection
                    quickActions
                    recommendedSection
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, Theme.Spacing.xxl)
                .navigationDestination(for: Course.self) { course in
                    CourseDetailView(course: course)
                }
            }
            .background(Theme.Palette.background)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                profile = await appState.service.currentUser()
                next = await appState.service.nextRound()
                recommended = await appState.service.fetchRecommended()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                EyebrowText(todayString)
                greeting
            }
            Spacer(minLength: Theme.Spacing.sm)
            Button {
                Haptics.tap()
                appState.selectedTab = .profile
            } label: {
                AvatarView(
                    name: profile?.fullName ?? "Golfer",
                    imageName: profile?.avatarImageName,
                    size: 46
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var greeting: some View {
        HStack(spacing: 0) {
            Text("Good \(partOfDay), ")
                .foregroundStyle(Theme.Palette.ink)
            Text(firstName)
                .foregroundStyle(Theme.Palette.primary)
        }
        .font(Theme.Typography.largeTitle)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        if let next {
            NavigationLink(value: next.course) {
                NextRoundHero(booking: next)
            }
            .buttonStyle(.plain)
        } else {
            NoUpcomingCard { appState.selectedTab = .book }
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: Theme.Spacing.md) {
            QuickActionCard(
                systemImage: "calendar",
                title: "Book a tee time",
                subtitle: "Find an open slot"
            ) { appState.selectedTab = .book }
            QuickActionCard(
                systemImage: "magnifyingglass",
                title: "Browse courses",
                subtitle: "500+ near you"
            ) { appState.selectedTab = .browse }
        }
    }

    // MARK: - Recommended

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Recommended near you", actionTitle: "See all") {
                appState.selectedTab = .browse
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    ForEach(recommended) { course in
                        NavigationLink(value: course) {
                            RecommendedCourseCard(course: course)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
            // Let the rail bleed to the screen edges while cards align to the inset.
            .padding(.horizontal, -Theme.screenPadding)
        }
    }

    // MARK: - Derived copy

    private var firstName: String {
        profile?.firstName ?? "Golfer"
    }

    private var partOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case ..<12: return "morning"
        case ..<17: return "afternoon"
        default: return "evening"
        }
    }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMMM d"
        return formatter.string(from: Date()).uppercased()
    }
}

// MARK: - Next round hero card

private struct NextRoundHero: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                EyebrowText("Your next round", onDark: true)
                Text(booking.course.name)
                    .font(Theme.Typography.titleHero)
                    .foregroundStyle(Theme.Palette.onDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(booking.course.location) · Par \(booking.course.par)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.onDarkSecondary)
            }

            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                StatColumn(label: "Date", value: dateValue, onDark: true)
                Spacer(minLength: Theme.Spacing.sm)
                StatColumn(label: "Tee time", value: booking.teeTime.timeDisplay, onDark: true)
                Spacer(minLength: Theme.Spacing.sm)
                StatColumn(label: "Players", value: "\(booking.players)", onDark: true)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.primary)
        .overlay(alignment: .topTrailing) {
            TopographicLines()
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .shadow(color: Theme.Palette.primary.opacity(0.28), radius: 18, x: 0, y: 10)
    }

    private var dateValue: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: booking.date)
    }
}

// MARK: - Empty state

private struct NoUpcomingCard: View {
    let onBook: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "flag.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.Palette.primary)
                .frame(width: 44, height: 44)
                .background(
                    Theme.Palette.surfaceMuted,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("No upcoming rounds")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Your next tee time will show up here.")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            Spacer(minLength: Theme.Spacing.sm)
            Button("Book a tee time", action: onBook)
                .font(Theme.Typography.button)
                .foregroundStyle(Theme.Palette.primary)
                .fixedSize()
        }
        .gsCard()
    }
}

// MARK: - Recommended course card

private struct RecommendedCourseCard: View {
    let course: Course

    private let cardWidth: CGFloat = 230

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            CourseImage(course: course)
                .frame(width: cardWidth, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    PriceTag(amount: course.greenFee)
                        .padding(Theme.Spacing.sm)
                }

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(course.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                Text(course.location)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .lineLimit(1)
                RatingLabel(
                    rating: course.rating,
                    trailing: "\(course.slotsAvailableToday) slots"
                )
                .padding(.top, 2)
            }
        }
        .frame(width: cardWidth, alignment: .leading)
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
