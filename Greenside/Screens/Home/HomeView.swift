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
                VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                    header
                    heroSection
                    quickActions
                    recommendedSection
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, Theme.Spacing.sm)
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
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
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
                    size: 50
                )
            }
            .buttonStyle(PressScaleStyle(scale: 0.92))
            .padding(.top, Theme.Spacing.md)
        }
    }

    /// Big editorial greeting — "Good <part>," on one line, the first name in
    /// accent green beneath it. Both lines guard against bad wrapping.
    private var greeting: some View {
        VStack(alignment: .leading, spacing: -2) {
            Text("Good \(partOfDay),")
                .foregroundStyle(Theme.Palette.ink)
            Text(firstName)
                .foregroundStyle(Theme.Palette.accent)
        }
        .font(Theme.Typography.display(40, .bold))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: firstName)
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        if let next {
            NavigationLink(value: next.course) {
                NextRoundHero(booking: next)
            }
            .buttonStyle(PressScaleStyle())
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: next.id)
        } else {
            NoUpcomingCard { appState.selectedTab = .book }
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: Theme.Spacing.md) {
            HomeQuickAction(
                systemImage: "calendar",
                title: "Book a tee time",
                subtitle: "Find an open slot"
            ) { appState.selectedTab = .book }
            HomeQuickAction(
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
                        .buttonStyle(PressScaleStyle())
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

// MARK: - Home quick action

/// Icon + title + subtitle card for the Home quick-action row. Mirrors the
/// shared `QuickActionCard` visual but drives the tap through `PressScaleStyle`
/// so both primary shortcuts get the springy press.
private struct HomeQuickAction: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Palette.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Theme.Palette.surfaceMuted,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gsCard()
        }
        .buttonStyle(PressScaleStyle())
    }
}

// MARK: - Next round hero card

private struct NextRoundHero: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
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

            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
                HeroStat(label: "Date", value: dateValue, unit: monthValue)
                Spacer(minLength: Theme.Spacing.xs)
                HeroStat(label: "Tee time", value: teeValue, unit: teePeriod)
                Spacer(minLength: Theme.Spacing.xs)
                HeroStat(label: "Players", value: "\(booking.players)", unit: playersUnit)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.primary)
        .overlay(alignment: .topTrailing) {
            TopographicLines()
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .shadow(color: Theme.Palette.primary.opacity(0.28), radius: 22, x: 0, y: 12)
    }

    // MARK: Derived stat parts

    private var dateValue: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: booking.date)
    }

    private var monthValue: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: booking.date).uppercased()
    }

    /// The clock portion of "9:00 AM".
    private var teeValue: String {
        booking.teeTime.timeDisplay
            .split(separator: " ")
            .first
            .map(String.init) ?? booking.teeTime.timeDisplay
    }

    /// The meridiem portion of "9:00 AM".
    private var teePeriod: String {
        booking.teeTime.timeDisplay
            .split(separator: " ")
            .dropFirst()
            .first
            .map(String.init) ?? ""
    }

    private var playersUnit: String {
        booking.players == 1 ? "player" : "players"
    }
}

/// A hero stat: small onDark eyebrow, a large display number, and a tiny muted
/// unit riding its baseline. Numbers animate with `.numericText()`.
private struct HeroStat: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label.uppercased())
                .font(Theme.Typography.caption)
                .tracking(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(Theme.Palette.onDarkSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.Typography.display(30, .bold))
                    .foregroundStyle(Theme.Palette.onDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                if !unit.isEmpty {
                    Text(unit)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.onDarkSecondary)
                        .lineLimit(1)
                }
            }
        }
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
