import SwiftUI

/// Profile tab root. Shows the golfer's identity, loyalty status, quick stats,
/// their recent points activity, past rounds, and a sign-out control. Owns its
/// own `NavigationStack` per the tab-root navigation contract.
struct ProfileView: View {
    @Environment(AppState.self) private var appState

    @State private var profile: UserProfile?
    @State private var activity: [LoyaltyActivity] = []
    @State private var rounds: [Booking] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile {
                    content(for: profile)
                } else {
                    loading
                }
            }
            .background(Theme.Palette.background)
            .navigationTitle("Profile")
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
            .tint(Theme.Palette.primary)
            .frame(maxWidth: .infinity)
            .padding(.top, Theme.Spacing.xxxl * 2)
    }

    // MARK: - Content

    private func content(for profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            ProfileHeader(profile: profile)

            LoyaltyHeroCard(profile: profile)

            QuickStatsCard(profile: profile, roundsCount: rounds.count)

            if !activity.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader(title: "Recent activity")
                    ActivityCard(activity: activity)
                }
            }

            if !rounds.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader(title: "My rounds")
                    RoundsCard(rounds: rounds)
                }
            }

            Button {
                appState.signOut()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Sign out")
                        .font(Theme.Typography.button)
                }
                .foregroundStyle(Theme.Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    Theme.Palette.surface,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(Theme.Palette.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, Theme.Spacing.xs)
        .padding(.bottom, Theme.Spacing.xxxl)
    }
}

// MARK: - Header

private struct ProfileHeader: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            AvatarView(name: profile.fullName, imageName: profile.avatarImageName, size: 72)

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.fullName)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.ink)
                Text(profile.email)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                Text("Member since \(memberYear)")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }

            Spacer(minLength: 0)
        }
    }

    private var memberYear: String {
        let year = Calendar.current.component(.year, from: profile.memberSince)
        return String(year)
    }
}

// MARK: - Loyalty hero

private struct LoyaltyHeroCard: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowText("Loyalty", onDark: true)
                Spacer(minLength: Theme.Spacing.sm)
                Text("Level \(profile.loyaltyLevel)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.onDarkSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.loyaltyTier)
                    .font(Theme.Typography.titleHero)
                    .foregroundStyle(Theme.Palette.onDark)
                Text("\(profile.points) pts")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Palette.lime)
                    .contentTransition(.numericText())
            }
            .padding(.top, Theme.Spacing.xxs)

            LoyaltyProgressBar(progress: profile.tierProgress)
                .padding(.top, Theme.Spacing.xs)

            Text("\(profile.pointsToNextTier) pts to next tier")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.onDarkSecondary)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Theme.Palette.primary
                TopographicLines()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .shadow(color: Theme.Palette.primary.opacity(0.28), radius: 18, y: 10)
    }
}

private struct LoyaltyProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                Capsule()
                    .fill(Theme.Palette.lime)
                    .frame(width: max(10, geo.size.width * clamped))
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Quick stats

private struct QuickStatsCard: View {
    let profile: UserProfile
    let roundsCount: Int

    var body: some View {
        HStack(alignment: .top) {
            StatColumn(label: "Handicap", value: handicapValue)
            Spacer(minLength: Theme.Spacing.sm)
            StatColumn(label: "Rounds", value: "\(roundsCount)", alignment: .center)
            Spacer(minLength: Theme.Spacing.sm)
            StatColumn(label: "Points", value: "\(profile.points)", alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .gsCard()
    }

    private var handicapValue: String {
        if let handicap = profile.handicap {
            return String(format: "%.1f", handicap)
        }
        return "—"
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
                        .overlay(Theme.Palette.hairline)
                        .padding(.leading, 40 + Theme.Spacing.sm)
                }
            }
        }
        .gsCard()
    }
}

private struct ActivityRow: View {
    let item: LoyaltyActivity

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: item.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Palette.primary)
                .frame(width: 40, height: 40)
                .background(Theme.Palette.surfaceMuted, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text(item.dateDisplay)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }

            Spacer(minLength: Theme.Spacing.sm)

            Text(item.pointsDisplay)
                .font(Theme.Typography.callout)
                .foregroundStyle(item.points >= 0 ? Theme.Palette.accent : Theme.Palette.inkSecondary)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - My rounds

private struct RoundsCard: View {
    let rounds: [Booking]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rounds.enumerated()), id: \.element.id) { index, booking in
                RoundRow(booking: booking)
                if index < rounds.count - 1 {
                    Divider()
                        .overlay(Theme.Palette.hairline)
                        .padding(.leading, 48 + Theme.Spacing.sm)
                }
            }
        }
        .gsCard()
    }
}

private struct RoundRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            CourseImage(course: booking.course)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(booking.course.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text("\(booking.dateDisplay) · \(booking.teeTime.timeDisplay)")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }

            Spacer(minLength: Theme.Spacing.sm)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(booking.players)p")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Palette.ink)
                Text(booking.confirmationCode)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
