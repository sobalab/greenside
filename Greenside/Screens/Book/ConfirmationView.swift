import SwiftUI

/// Terminal success screen of the booking wizard. Reads the finished booking
/// from `appState.booking.confirmedBooking` (falling back to the in-flight
/// `draft` so it always renders gracefully) and offers a celebratory summary
/// with two exits: back to Home or straight to the user's rounds.
struct ConfirmationView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var booking = appState.booking

        // Prefer the server-confirmed booking, but degrade to the live draft so
        // the screen never renders empty even if we arrive without a result.
        let result = booking.confirmedBooking ?? booking.draft

        ZStack {
            Theme.Palette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer(minLength: Theme.Spacing.xxl)

                    SuccessEmblem()

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("You're booked!")
                            .font(Theme.Typography.largeTitle)
                            .foregroundStyle(Theme.Palette.ink)
                        Text("Your tee time is confirmed.")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                    }
                    .multilineTextAlignment(.center)

                    if let result {
                        ConfirmationCard(booking: result)

                        Label("Added to your rounds", systemImage: "checkmark.seal.fill")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Palette.accent)
                    }

                    Spacer(minLength: Theme.Spacing.lg)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.screenPadding)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Spacing.sm) {
                Button("Done") {
                    booking.reset()
                    appState.selectedTab = .home
                }
                .buttonStyle(GSPrimaryButtonStyle())

                Button("View my rounds") {
                    booking.reset()
                    appState.selectedTab = .profile
                }
                .font(Theme.Typography.button)
                .foregroundStyle(Theme.Palette.accent)
                .padding(.vertical, Theme.Spacing.xxs)
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xs)
            .background(Theme.Palette.background.opacity(0.98))
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Success emblem

/// The large gradient circle with a bold white checkmark, wrapped in a soft
/// concentric halo to give the moment a little lift.
private struct SuccessEmblem: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.Palette.lime.opacity(0.18))
                .frame(width: 132, height: 132)

            Circle()
                .fill(Theme.brandGradient)
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Theme.Palette.onDark)
                )
                .shadow(color: Theme.Palette.primary.opacity(0.28), radius: 18, y: 10)
        }
    }
}

// MARK: - Confirmation card

/// White card summarizing the confirmed round: course, key stats, and the
/// dashed confirmation-code pill.
private struct ConfirmationCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(booking.course.name)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Palette.ink)
                Text(booking.course.location)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }

            Divider()
                .overlay(Theme.Palette.hairline)

            HStack(alignment: .top) {
                StatColumn(label: "Date", value: Self.shortDate(booking.date))
                Spacer(minLength: Theme.Spacing.sm)
                StatColumn(label: "Tee time", value: booking.teeTime.timeDisplay, alignment: .center)
                Spacer(minLength: Theme.Spacing.sm)
                StatColumn(label: "Players", value: "\(booking.players)", alignment: .trailing)
            }

            CodePill(code: booking.confirmationCode)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gsCard(padding: Theme.Spacing.lg, cornerRadius: Theme.Radius.lg)
    }

    private static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - Confirmation code pill

private struct CodePill: View {
    let code: String

    var body: some View {
        HStack {
            EyebrowText("Confirmation")
            Spacer(minLength: Theme.Spacing.sm)
            Text(code.isEmpty ? "—" : code)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.primary)
                .tracking(1.5)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surfaceMuted.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .strokeBorder(
                    Theme.Palette.primary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1.2, dash: [6])
                )
        )
    }
}

#Preview {
    let state = AppState()
    state.booking.start(course: SampleData.pebbleBeach)
    return NavigationStack {
        ConfirmationView()
    }
    .environment(state)
}
