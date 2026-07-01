import SwiftUI

/// Terminal success screen — Birdie style. A living dawn-gradient emblem, an
/// oversized headline, and a paper summary card. Reads the confirmed booking
/// (falling back to the live draft) so it always renders gracefully.
struct ConfirmationView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var booking = appState.booking
        let result = booking.confirmedBooking ?? booking.draft

        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                SuccessEmblem()

                VStack(spacing: 8) {
                    Text("You're booked!")
                        .font(.display(44, .bold))
                        .foregroundStyle(Theme.Palette.charcoal)
                    Text("Your tee time is confirmed.")
                        .font(.body(16, .regular))
                        .foregroundStyle(Theme.Palette.muted)
                }
                .multilineTextAlignment(.center)

                if let result {
                    ConfirmationCard(booking: result)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                        Text("Added to your rounds")
                            .font(.body(13, .medium))
                    }
                    .foregroundStyle(Theme.Palette.muted)
                }

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) {
                PillButton(title: "Done", style: .volt, fill: true) {
                    booking.reset()
                    appState.selectedTab = .home
                }
                Button {
                    Haptics.tap()
                    booking.reset()
                    appState.selectedTab = .profile
                } label: {
                    Text("View my rounds")
                        .font(.body(15, .semibold))
                        .foregroundStyle(Theme.Palette.charcoal)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PressScaleStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Theme.Palette.ground)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Success emblem

private struct SuccessEmblem: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.Palette.dawnStops[2].opacity(0.2))
                .frame(width: 136, height: 136)
            DawnGradient()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: Theme.Palette.dawnStops[1].opacity(0.4), radius: 18, y: 10)
        }
    }
}

// MARK: - Confirmation card

private struct ConfirmationCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 2) {
                Text(booking.course.name)
                    .font(.display(24, .bold))
                    .foregroundStyle(Theme.Palette.charcoal)
                Text(booking.course.location)
                    .font(.body(13, .regular))
                    .foregroundStyle(Theme.Palette.muted)
            }

            Rectangle().fill(Theme.Palette.mist).frame(height: 1)

            HStack(alignment: .top) {
                MetricBlock(value: Self.shortDate(booking.date), unit: "date", tone: .muted, size: 22).fixedSize()
                Spacer(minLength: 8)
                MetricBlock(value: booking.teeTime.timeDisplay, unit: "tee", tone: .muted, size: 22).fixedSize()
                Spacer(minLength: 8)
                MetricBlock(value: "\(booking.players)", unit: "players", tone: .volt, size: 22).fixedSize()
            }

            CodePill(code: booking.confirmationCode)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.Palette.paper, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
    }

    private static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - Code pill

private struct CodePill: View {
    let code: String

    var body: some View {
        HStack {
            Text("Confirmation")
                .font(.body(12, .semibold))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.muted)
            Spacer(minLength: 8)
            Text(code.isEmpty ? "—" : code)
                .font(.body(16, .semibold))
                .foregroundStyle(Theme.Palette.charcoal)
                .tracking(1.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.Palette.mist.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.Palette.muted.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [6]))
        )
    }
}

#Preview {
    let state = AppState()
    state.booking.start(course: SampleData.pebbleBeach)
    return NavigationStack { ConfirmationView() }
        .environment(state)
}
