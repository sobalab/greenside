import SwiftUI

/// Profile tab root. Shows the golfer's identity, loyalty status, quick stats,
/// their recent points activity, past rounds, and a sign-out control. Owns its
/// own `NavigationStack` per the tab-root navigation contract.
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
                        .transition(.opacity)
                } else {
                    loading
                }
            }
            .background(Theme.Palette.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: profile == nil)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
            ProfileHeader(profile: profile)

            LoyaltyHeroCard(profile: profile)

            StatsRow(profile: profile, roundsCount: rounds.count)

            if !activity.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader(title: "Recent activity")
                    ActivityCard(activity: activity)
                }
            }

            if !rounds.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader(title: "My rounds")
                    RoundsCard(rounds: rounds, nextRoundID: nextRoundID)
                }
            }

            Button {
                Haptics.tap()
                showSignOutConfirm = true
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
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xxxl)
    }

    /// The id of the nearest upcoming (or most recent) round, used to give one
    /// row a subtle brand accent.
    private var nextRoundID: Booking.ID? {
        let now = Date()
        let upcoming = rounds
            .filter { $0.date >= now }
            .min(by: { $0.date < $1.date })
        return (upcoming ?? rounds.min(by: { $0.date < $1.date }))?.id
    }
}

// MARK: - Header

private struct ProfileHeader: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                AvatarView(name: profile.fullName, imageName: profile.avatarImageName, size: 68)

                VStack(alignment: .leading, spacing: 4) {
                    EyebrowText("Your profile")
                    Text(profile.email)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)
            }

            Text(profile.fullName)
                .font(Theme.Typography.display(40, .bold))
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)

            Text("Member since \(memberYear)")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.inkTertiary)
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
        VStack(spacing: Theme.Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowText("Loyalty", onDark: true)
                Spacer(minLength: Theme.Spacing.sm)
                Text("Level \(profile.loyaltyLevel)")
                    .font(Theme.Typography.caption)
                    .tracking(0.5)
                    .foregroundStyle(Theme.Palette.onDark)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.14), in: Capsule())
                    .contentTransition(.numericText())
            }

            ProgressRing(
                progress: profile.tierProgress,
                lineWidth: 14,
                trackColor: Color.white.opacity(0.16)
            ) {
                VStack(spacing: 2) {
                    Text("\(profile.points)")
                        .font(Theme.Typography.display(38, .bold))
                        .foregroundStyle(Theme.Palette.onDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText())
                    Text("PTS")
                        .font(Theme.Typography.caption)
                        .tracking(1.5)
                        .foregroundStyle(Theme.Palette.onDarkSecondary)
                    Text(profile.loyaltyTier)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Palette.lime)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.top, Theme.Spacing.xxs)
                }
                .padding(.horizontal, Theme.Spacing.xs)
            }
            .frame(width: 176, height: 176)

            VStack(spacing: Theme.Spacing.xxs) {
                Text("Level \(profile.loyaltyLevel) · \(profile.loyaltyTier)")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.onDark)
                    .contentTransition(.numericText())
                HStack(spacing: 5) {
                    Text("\(profile.pointsToNextTier)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Palette.lime)
                        .contentTransition(.numericText())
                    Text("pts to next tier")
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.onDarkSecondary)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
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

// MARK: - Stats row

private struct StatsRow: View {
    let profile: UserProfile
    let roundsCount: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            HeroMetric(value: "\(roundsCount)", unit: nil, label: "Rounds")
            HeroMetric(value: handicapValue, unit: nil, label: "Handicap")
            HeroMetric(value: "\(profile.points)", unit: "pts", label: "Points")
        }
    }

    private var handicapValue: String {
        if let handicap = profile.handicap {
            return String(format: "%.1f", handicap)
        }
        return "—"
    }
}

/// A single editorial metric block: a large display number with an optional tiny
/// unit, over an uppercase label. Guards hard against wrapping.
private struct HeroMetric: View {
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.Typography.display(30, .bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkTertiary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.55)

            Text(label.uppercased())
                .font(Theme.Typography.caption)
                .tracking(0.6)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gsCard(padding: Theme.Spacing.md)
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
                        .padding(.leading, 44 + Theme.Spacing.sm)
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.primary)
                .frame(width: 44, height: 44)
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
                .font(Theme.Typography.title2)
                .foregroundStyle(item.points >= 0 ? Theme.Palette.accent : Theme.Palette.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - My rounds

private struct RoundsCard: View {
    let rounds: [Booking]
    let nextRoundID: Booking.ID?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rounds.enumerated()), id: \.element.id) { index, booking in
                NavigationLink(value: booking.course) {
                    RoundRow(booking: booking, isNext: booking.id == nextRoundID)
                }
                .buttonStyle(PressScaleStyle())
                .simultaneousGesture(TapGesture().onEnded { Haptics.selection() })

                if index < rounds.count - 1 {
                    Divider()
                        .overlay(Theme.Palette.hairline)
                        .padding(.leading, 52 + Theme.Spacing.sm)
                }
            }
        }
        .gsCard(padding: Theme.Spacing.xs)
    }
}

private struct RoundRow: View {
    let booking: Booking
    let isNext: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            CourseImage(course: booking.course)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                if isNext {
                    Text("UP NEXT")
                        .font(Theme.Typography.caption)
                        .tracking(0.8)
                        .foregroundStyle(Theme.Palette.accent)
                }
                Text(booking.course.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(booking.dateDisplay) · \(booking.teeTime.timeDisplay)")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }

            Spacer(minLength: Theme.Spacing.sm)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(booking.players)")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Palette.ink)
                        .contentTransition(.numericText())
                    Text(booking.players == 1 ? "player" : "players")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkTertiary)
                }
                Text(booking.confirmationCode)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Palette.inkTertiary)
                .padding(.leading, 2)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.xs)
        .background {
            if isNext {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Palette.primary.opacity(0.05))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Theme.brandGradient)
                            .frame(width: 3)
                            .padding(.vertical, Theme.Spacing.sm)
                    }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
