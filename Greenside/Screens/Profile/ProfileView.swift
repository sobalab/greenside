import SwiftUI

/// Profile tab root, Birdie style. The golfer's identity, loyalty status, quick
/// stats, upcoming/past rounds, points activity, and a sign-out control — all on
/// the sage ground. Owns its own `NavigationStack` per the tab-root contract.
struct ProfileView: View {
    @Environment(AppState.self) private var appState

    @State private var profile: UserProfile?
    @State private var activity: [LoyaltyActivity] = []
    @State private var rounds: [Booking] = []
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile {
                    content(for: profile)
                } else {
                    loading
                }
            }
            .scrollIndicators(.hidden)
            .background(Theme.Palette.ground.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: Course.self) { course in
                CourseDetailView(course: course)
            }
            .confirmationDialog("Sign out of Greenside?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    Haptics.impact()
                    appState.signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .task {
            profile = await appState.service.currentUser()
            activity = await appState.service.loyaltyActivity()
            rounds = await appState.service.myRounds()
        }
    }

    // MARK: - Loading

    private var loading: some View {
        ProgressView()
            .tint(Theme.Palette.charcoal)
            .frame(maxWidth: .infinity)
            .padding(.top, 160)
    }

    // MARK: - Content

    private func content(for profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 34) {
            ProfileHeader(profile: profile)

            LoyaltyHeroCard(profile: profile)

            StatsRow(profile: profile, roundsCount: rounds.count)

            if !rounds.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("My rounds")
                        .font(.display(24, .bold))
                        .foregroundStyle(Theme.Palette.charcoal)
                    RoundsList(rounds: rounds)
                }
            }

            if !activity.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Recent activity")
                        .font(.display(24, .bold))
                        .foregroundStyle(Theme.Palette.charcoal)
                    ActivityCard(activity: activity)
                }
            }

            PillButton(title: "Sign out", style: .paper, fill: true) {
                Haptics.tap()
                showSignOutConfirm = true
            }
            .overlay(
                Capsule().stroke(Theme.Palette.charcoal.opacity(0.08), lineWidth: 1)
            )
            .padding(.top, 4)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 56)
    }
}

// MARK: - Header

private struct ProfileHeader: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("PROFILE")
                    .font(.body(12, .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.Palette.muted)
                Text(profile.fullName)
                    .font(.display(38, .bold))
                    .foregroundStyle(Theme.Palette.charcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 14) {
                AvatarView(name: profile.fullName, imageName: profile.avatarImageName, size: 64)

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.email)
                        .font(.body(14, .regular))
                        .foregroundStyle(Theme.Palette.muted)
                    Text("Member since \(memberYear)")
                        .font(.body(13, .regular))
                        .foregroundStyle(Theme.Palette.muted)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var memberYear: String {
        String(Calendar.current.component(.year, from: profile.memberSince))
    }
}

// MARK: - Loyalty hero

private struct LoyaltyHeroCard: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("LOYALTY")
                    .font(.body(12, .semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.Palette.paper.opacity(0.6))
                Spacer(minLength: 8)
                Text("Level \(profile.loyaltyLevel)")
                    .font(.body(13, .medium))
                    .foregroundStyle(Theme.Palette.paper.opacity(0.7))
            }

            HStack(alignment: .firstTextBaseline) {
                Text(profile.loyaltyTier)
                    .font(.display(30, .bold))
                    .foregroundStyle(Theme.Palette.paper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 12)
                Text("\(profile.points) pts")
                    .font(.display(22, .bold))
                    .foregroundStyle(Theme.Palette.volt)
                    .contentTransition(.numericText())
            }

            ProgressCapsule(progress: profile.tierProgress)
                .padding(.top, 2)

            Text("\(profile.pointsToNextTier) pts to next tier")
                .font(.body(13, .regular))
                .foregroundStyle(Theme.Palette.paper.opacity(0.7))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                Theme.Palette.charcoal
                ContourHero(tint: Theme.Palette.volt, seed: birdieSeed(profile.loyaltyTier), maxOpacity: 0.25)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 20, y: 12)
    }
}

private struct ProgressCapsule: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(Theme.Palette.volt)
                    .frame(width: max(10, geo.size.width * clamped))
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Stats

private struct StatsRow: View {
    let profile: UserProfile
    let roundsCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            MetricBlock(value: handicapValue, unit: "handicap", tone: .volt)
                .frame(maxWidth: .infinity, alignment: .leading)
            MetricBlock(value: "\(roundsCount)", unit: "rounds", tone: .muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            MetricBlock(value: "\(profile.points)", unit: "points", tone: .muted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Theme.Palette.paper, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Theme.Palette.charcoal.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }

    private var handicapValue: String {
        if let handicap = profile.handicap {
            return String(format: "%.1f", handicap)
        }
        return "—"
    }
}

// MARK: - My rounds

private struct RoundsList: View {
    let rounds: [Booking]

    /// The first round whose date is still in the future (nearest upcoming).
    private var nearestUpcomingID: UUID? {
        let now = Date()
        return rounds
            .filter { $0.date > now }
            .min(by: { $0.date < $1.date })?
            .id
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rounds) { booking in
                NavigationLink(value: booking.course) {
                    RoundCard(booking: booking, isNearest: booking.id == nearestUpcomingID)
                }
                .buttonStyle(PressScaleStyle(scale: 0.98))
            }
        }
    }
}

private struct RoundCard: View {
    let booking: Booking
    let isNearest: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isNearest ? 14 : 0) {
            if isNearest {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Palette.charcoal)
                    Text("Tees off \(countdown)")
                        .font(.body(13, .semibold))
                        .foregroundStyle(Theme.Palette.charcoal)
                }
            }

            HStack(spacing: 14) {
                CourseImage(course: booking.course)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(booking.course.name)
                        .font(.body(16, .semibold))
                        .foregroundStyle(Theme.Palette.charcoal)
                        .lineLimit(1)
                    Text("\(booking.dateDisplay) · \(booking.teeTime.timeDisplay)")
                        .font(.body(13, .regular))
                        .foregroundStyle(isNearest ? Theme.Palette.charcoal.opacity(0.7) : Theme.Palette.muted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isNearest ? Theme.Palette.charcoal.opacity(0.6) : Theme.Palette.muted)
            }
        }
        .padding(isNearest ? 18 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isNearest {
                DawnGradient()
            } else {
                Theme.Palette.paper
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.Palette.charcoal.opacity(isNearest ? 0 : 0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isNearest ? 0.08 : 0.05), radius: 14, y: 6)
    }

    /// A simple relative countdown like "today", "tomorrow", "in 3 days".
    private var countdown: String {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: booking.date)
        let days = cal.dateComponents([.day], from: start, to: target).day ?? 0
        switch days {
        case ..<0: return "soon"
        case 0: return "today"
        case 1: return "tomorrow"
        default: return "in \(days) days"
        }
    }
}

// MARK: - Recent activity

private struct ActivityCard: View {
    let activity: [LoyaltyActivity]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(activity.enumerated()), id: \.element.id) { index, item in
                ActivityRow(item: item)
                if index < activity.count - 1 {
                    Divider()
                        .overlay(Theme.Palette.charcoal.opacity(0.06))
                        .padding(.leading, 54)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Theme.Palette.paper, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Theme.Palette.charcoal.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }
}

private struct ActivityRow: View {
    let item: LoyaltyActivity

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Palette.charcoal)
                .frame(width: 40, height: 40)
                .background(Theme.Palette.mist, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body(15, .semibold))
                    .foregroundStyle(Theme.Palette.charcoal)
                Text(item.dateDisplay)
                    .font(.body(13, .regular))
                    .foregroundStyle(Theme.Palette.muted)
            }

            Spacer(minLength: 8)

            Text(item.pointsDisplay)
                .font(.body(15, .semibold))
                .foregroundStyle(item.points >= 0 ? Theme.Palette.voltDeep : Theme.Palette.muted)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
