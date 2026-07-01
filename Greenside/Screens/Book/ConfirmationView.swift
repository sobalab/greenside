import SwiftUI

/// Terminal success screen of the booking wizard. Reads the finished booking
/// from `appState.booking.confirmedBooking` (falling back to the in-flight
/// `draft` so it always renders gracefully) and offers a celebratory summary
/// with two exits: back to Home or straight to the user's rounds.
struct ConfirmationView: View {
    @Environment(AppState.self) private var appState

    @State private var didAppear = false

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
                    Spacer(minLength: Theme.Spacing.xl)

                    SuccessEmblem(didAppear: didAppear)

                    VStack(spacing: Theme.Spacing.sm) {
                        Text("You're\nbooked!")
                            .font(Theme.Typography.display(52, .bold))
                            .foregroundStyle(Theme.Palette.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .lineSpacing(-4)
                        Text("Your tee time is confirmed.")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 12)

                    if let result {
                        ConfirmationCard(booking: result)
                            .opacity(didAppear ? 1 : 0)
                            .offset(y: didAppear ? 0 : 16)

                        Label("Added to your rounds", systemImage: "checkmark.seal.fill")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Palette.accent)
                            .opacity(didAppear ? 1 : 0)
                    }

                    Spacer(minLength: Theme.Spacing.lg)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.screenPadding)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    Haptics.impact()
                    booking.reset()
                    appState.selectedTab = .home
                } label: {
                    Text("Done")
                }
                .buttonStyle(GSPrimaryButtonStyle())

                Button {
                    Haptics.tap()
                    booking.reset()
                    appState.selectedTab = .profile
                } label: {
                    Text("View my rounds")
                }
                .font(Theme.Typography.button)
                .foregroundStyle(Theme.Palette.accent)
                .buttonStyle(PressScaleStyle())
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
        .task {
            Haptics.selection()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                didAppear = true
            }
        }
    }
}

// MARK: - Success emblem

/// The large living-gradient circle with a bold white checkmark, wrapped in a
/// soft concentric halo. Springs in from a slightly compressed scale to give
/// the celebratory moment a confident lift.
private struct SuccessEmblem: View {
    let didAppear: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.Palette.lime.opacity(0.16))
                .frame(width: 168, height: 168)
                .blur(radius: 4)

            Circle()
                .fill(Theme.Palette.lime.opacity(0.22))
                .frame(width: 132, height: 132)

            Circle()
                .fill(Color.clear)
                .frame(width: 104, height: 104)
                .overlay(BrandGradientDrift().clipShape(Circle()))
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Theme.Palette.onDark)
                )
                .shadow(color: Theme.Palette.primary.opacity(0.30), radius: 20, y: 12)
        }
        .scaleEffect(didAppear ? 1 : 0.8)
        .opacity(didAppear ? 1 : 0)
    }
}

// MARK: - Confirmation card

/// White card summarizing the confirmed round: course, hero stats, and the
/// dashed confirmation-code pill.
private struct ConfirmationCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                EyebrowText("Your round")
                Text(booking.course.name)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(booking.course.location)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }

            Divider()
                .overlay(Theme.Palette.hairline)

            HStack(alignment: .bottom) {
                HeroStat(label: "Date", value: Self.shortDate(booking.date), alignment: .leading)
                Spacer(minLength: Theme.Spacing.sm)
                HeroStat(label: "Tee time", value: booking.teeTime.timeDisplay, unit: nil, alignment: .center)
                Spacer(minLength: Theme.Spacing.sm)
                HeroStat(label: "Players", value: "\(booking.players)", alignment: .trailing)
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

// MARK: - Hero stat

/// A single large summary number with a small muted label above it. Scale
/// contrast — not colour — carries the hierarchy. Numbers use numericText so
/// they animate cleanly if the underlying booking changes.
private struct HeroStat: View {
    let label: String
    let value: String
    var unit: String? = nil
    var alignment: HorizontalAlignment = .leading

    private var textAlignment: TextAlignment {
        switch alignment {
        case .trailing: return .trailing
        case .center: return .center
        default: return .leading
        }
    }

    var body: some View {
        VStack(alignment: alignment, spacing: Theme.Spacing.xxs) {
            Text(label.uppercased())
                .font(Theme.Typography.caption)
                .tracking(0.8)
                .foregroundStyle(Theme.Palette.inkTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.Typography.display(26, .bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit {
                    Text(unit)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
            }
        }
        .multilineTextAlignment(textAlignment)
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
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
                .contentTransition(.numericText())
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
