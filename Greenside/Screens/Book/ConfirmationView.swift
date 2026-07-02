import SwiftUI

/// Terminal success screen of the booking wizard — a full-bleed green takeover
/// styled as a boarding-pass-style ticket. Reads the finished booking from
/// `appState.booking.confirmedBooking` (falling back to the live `draft` so it
/// always renders) and offers Apple Wallet + "View in My Rounds" exits.
struct ConfirmationView: View {
    @Environment(AppState.self) private var appState

    @State private var didAppear = false

    var body: some View {
        @Bindable var booking = appState.booking
        let result = booking.confirmedBooking ?? booking.draft

        ZStack {
            // Green topographic takeover background.
            Theme.Palette.primary.ignoresSafeArea()
            TopographicLines(opacity: 0.18).ignoresSafeArea().allowsHitTesting(false)

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    successEmblem

                    VStack(spacing: Theme.Spacing.sm) {
                        Text("You're set for the course!")
                            .font(Theme.Typography.display(34, .bold))
                            .foregroundStyle(Theme.Palette.onDark)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)
                        Text(subtitle(booking: booking))
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Palette.onDarkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 12)

                    if let result {
                        TicketCard(booking: result)
                            .opacity(didAppear ? 1 : 0)
                            .offset(y: didAppear ? 0 : 20)
                    }

                    Spacer(minLength: Theme.Spacing.md)
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
            }
        }
        .overlay(alignment: .topTrailing) { closeButton(booking: booking) }
        .safeAreaInset(edge: .bottom) { bottomBar(booking: booking) }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            Haptics.success()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                didAppear = true
            }
        }
    }

    // MARK: - Emblem

    private var successEmblem: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 124, height: 124)
                .blur(radius: 3)
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 92, height: 92)
            Image(systemName: "checkmark")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Theme.Palette.onDark)
        }
        .scaleEffect(didAppear ? 1 : 0.7)
        .opacity(didAppear ? 1 : 0)
    }

    private func subtitle(booking: BookingViewModel) -> String {
        if let email = booking.profile?.email {
            return "Booking confirmed. We've sent a confirmation email to \(email)."
        }
        return "Booking confirmed. A confirmation email is on its way."
    }

    // MARK: - Close

    private func closeButton(booking: BookingViewModel) -> some View {
        Button {
            Haptics.tap()
            booking.reset()
            appState.selectedTab = .home
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.Palette.onDark)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.16), in: Circle())
        }
        .buttonStyle(PressScaleStyle())
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Bottom actions

    private func bottomBar(booking: BookingViewModel) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button {
                Haptics.success()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "wallet.pass.fill")
                    Text("Add to Apple Wallet")
                }
                .font(Theme.Typography.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Color.black, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            }
            .buttonStyle(PressScaleStyle())

            Button {
                Haptics.tap()
                booking.reset()
                appState.selectedTab = .profile
            } label: {
                Text("View in My Rounds")
                    .font(Theme.Typography.button)
                    .foregroundStyle(Theme.Palette.onDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
        .background(
            LinearGradient(
                colors: [Theme.Palette.primary.opacity(0), Theme.Palette.primary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Ticket card

private struct TicketCard: View {
    let booking: Booking

    private let notchY: CGFloat = 86
    private let notchRadius: CGFloat = 11

    var body: some View {
        VStack(spacing: 0) {
            // Top stub: course + confirmed pill.
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(booking.course.name)
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(booking.course.location)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: Theme.Spacing.sm)
                confirmedPill
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(height: notchY)

            // Perforation line between the notches.
            DashedLine()
                .stroke(Theme.Palette.hairline, style: StrokeStyle(lineWidth: 1.4, dash: [5, 5]))
                .frame(height: 1)
                .padding(.horizontal, notchRadius + 8)

            // Detail stub: stats grid + barcode.
            VStack(spacing: Theme.Spacing.lg) {
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    ticketStat("DATE", booking.dateDisplay)
                    ticketStat("TEE TIME", booking.teeTime.timeDisplay)
                }
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    ticketStat("PLAYERS", "\(booking.players)")
                    ticketStat("TOTAL PAID", "$\(booking.total)")
                }
                Barcode(code: booking.confirmationCode)
                    .padding(.top, Theme.Spacing.xs)
            }
            .padding(Theme.Spacing.lg)
        }
        .background(
            TicketShape(notchY: notchY, notchRadius: notchRadius, cornerRadius: Theme.Radius.lg)
                .fill(Theme.Palette.surface)
                .shadow(color: .black.opacity(0.18), radius: 24, y: 14)
        )
    }

    private var confirmedPill: some View {
        Text("Confirmed")
            .font(Theme.Typography.footnote)
            .foregroundStyle(Theme.Palette.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .background(Theme.Palette.primary.opacity(0.10), in: Capsule())
    }

    private func ticketStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.Typography.caption)
                .tracking(0.8)
                .foregroundStyle(Theme.Palette.inkTertiary)
            Text(value)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Ticket shape (rounded rect with side notches at the perforation)

private struct TicketShape: Shape {
    var notchY: CGFloat
    var notchRadius: CGFloat = 11
    var cornerRadius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var base = Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
        let y = rect.minY + notchY
        let left = Path(ellipseIn: CGRect(x: rect.minX - notchRadius, y: y - notchRadius,
                                          width: notchRadius * 2, height: notchRadius * 2))
        let right = Path(ellipseIn: CGRect(x: rect.maxX - notchRadius, y: y - notchRadius,
                                           width: notchRadius * 2, height: notchRadius * 2))
        base = base.subtracting(left)
        base = base.subtracting(right)
        return base
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

// MARK: - Barcode

/// A decorative, deterministic barcode drawn from the confirmation code.
private struct Barcode: View {
    let code: String

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Canvas { context, size in
                let widths = Self.pattern(seed: code, count: 64)
                let total = widths.reduce(0, +)
                guard total > 0 else { return }
                var x: CGFloat = 0
                for (index, w) in widths.enumerated() {
                    let barWidth = w / total * size.width
                    if index % 2 == 0 {
                        let rect = CGRect(x: x, y: 0, width: max(0.6, barWidth - 0.6), height: size.height)
                        context.fill(Path(rect), with: .color(.black))
                    }
                    x += barWidth
                }
            }
            .frame(height: 58)

            Text(displayCode)
                .font(Theme.Typography.footnote)
                .tracking(4)
                .foregroundStyle(Theme.Palette.inkTertiary)
        }
    }

    private var displayCode: String {
        code.isEmpty ? "—" : code
    }

    /// Deterministic alternating bar/gap widths seeded by the code (LCG).
    private static func pattern(seed: String, count: Int) -> [CGFloat] {
        var hash: UInt64 = 5381
        for byte in seed.utf8 { hash = (hash &* 33) &+ UInt64(byte) }
        var state = hash | 1
        var widths: [CGFloat] = []
        for _ in 0..<count {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            widths.append(CGFloat(1 + Int((state >> 40) % 3)))
        }
        return widths
    }
}

#Preview {
    let state = AppState()
    state.booking.start(course: SampleData.bethpageBlack)
    return NavigationStack {
        ConfirmationView()
    }
    .environment(state)
}
