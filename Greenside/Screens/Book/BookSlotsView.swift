import SwiftUI

/// Book wizard — Step 1: choose a date and a tee time, then set the player count.
///
/// This is the root content hosted inside `BookRootView`'s `NavigationStack`, so
/// it never wraps itself in a stack. All state is read from the shared
/// `BookingViewModel` at `appState.booking`.
struct BookSlotsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var booking = appState.booking

        Group {
            if booking.course == nil {
                emptyState
            } else {
                content(booking: booking)
            }
        }
        .navigationTitle("Book")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.Palette.background)
        .task {
            await booking.loadProfileIfNeeded()
            if booking.slots.isEmpty {
                await booking.loadAvailability()
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer(minLength: 0)

            Image(systemName: "flag.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Theme.Palette.inkTertiary)

            VStack(spacing: Theme.Spacing.xs) {
                Text("Pick a course to book")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Browse our courses and start a booking.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            Button("Browse courses") {
                appState.selectedTab = .browse
            }
            .buttonStyle(GSPrimaryButtonStyle())
            .padding(.top, Theme.Spacing.xs)
            .padding(.horizontal, Theme.Spacing.xxl)

            Spacer(minLength: 0)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.screenPadding)
    }

    // MARK: - Main content

    @ViewBuilder
    private func content(booking: BookingViewModel) -> some View {
        let course = booking.course

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                if let course {
                    courseHeader(course)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    EyebrowText("Step 1 of 3")
                    Text("Pick a\ntee time")
                        .font(Theme.Typography.display(40, .bold))
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                }

                dateSelector(booking: booking)

                availabilitySection(booking: booking)

                playersRow(booking: booking)
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.xs)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar(booking: booking)
        }
    }

    // MARK: - Course header

    private func courseHeader(_ course: Course) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            CourseImage(course: course)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(course.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                Text(course.location)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                RatingLabel(rating: course.rating, trailing: course.priceDisplay + " green fee")
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .gsCard()
    }

    // MARK: - Date selector

    private func dateSelector(booking: BookingViewModel) -> some View {
        let days = Self.upcomingDays(count: 10)
        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            EyebrowText("Select a date")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(days, id: \.self) { day in
                        DayPill(
                            date: day,
                            isSelected: Calendar.current.isDate(booking.date, inSameDayAs: day),
                            isToday: Calendar.current.isDateInToday(day)
                        ) {
                            Haptics.selection()
                            Task { await booking.selectDate(day) }
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
            .padding(.horizontal, -Theme.screenPadding)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: booking.date)
        }
    }

    // MARK: - Availability

    @ViewBuilder
    private func availabilitySection(booking: BookingViewModel) -> some View {
        if booking.isLoadingSlots {
            VStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .tint(Theme.Palette.primary)
                Text("Finding open tee times…")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xxxl)
        } else if booking.slots.allSatisfy({ $0.teeTimes.isEmpty }) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.Palette.inkTertiary)
                Text("No tee times this day")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Try another date above.")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xxl)
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                ForEach(booking.slots) { slot in
                    if !slot.teeTimes.isEmpty {
                        periodSection(slot: slot, booking: booking)
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: booking.selectedTeeTime?.id)
        }
    }

    private func periodSection(slot: Slot, booking: BookingViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: slot.period.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.primary)
                EyebrowText(slot.period.rawValue)
                Spacer(minLength: 0)
                Text("\(slot.teeTimes.filter { !$0.isSoldOut }.count) open")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkTertiary)
                    .contentTransition(.numericText())
            }

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(slot.teeTimes) { teeTime in
                    TeeTimeRow(
                        teeTime: teeTime,
                        isSelected: booking.selectedTeeTime?.id == teeTime.id
                    ) {
                        Haptics.selection()
                        booking.select(teeTime: teeTime)
                    }
                }
            }
        }
    }

    // MARK: - Players

    private func playersRow(booking: BookingViewModel) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Players")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Up to 4 per booking")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            Spacer(minLength: 0)
            GSStepper(
                value: booking.players,
                canDecrement: booking.players > 1,
                canIncrement: booking.players < min(4, booking.selectedTeeTime?.spotsLeft ?? 4),
                onDecrement: booking.decrementPlayers,
                onIncrement: booking.incrementPlayers
            )
        }
        .gsCard()
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: booking.players)
    }

    // MARK: - Bottom CTA

    private func bottomBar(booking: BookingViewModel) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            if let teeTime = booking.selectedTeeTime {
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(teeTime.timeDisplay)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Palette.ink)
                            .contentTransition(.numericText())
                        Text("\(booking.players) \(booking.players == 1 ? "player" : "players")")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                            .contentTransition(.numericText())
                    }
                    Spacer(minLength: 0)
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxs) {
                        Text("$\(teeTime.price * booking.players)")
                            .font(Theme.Typography.display(28, .bold))
                            .foregroundStyle(Theme.Palette.ink)
                            .contentTransition(.numericText())
                        Text("total")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Palette.inkTertiary)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: booking.players)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: booking.selectedTeeTime?.id)
            }

            Button("Continue") {
                Haptics.impact()
                booking.goToConfirmProfile()
            }
            .buttonStyle(GSPrimaryButtonStyle(enabled: booking.canContinueFromSlots))
            .disabled(!booking.canContinueFromSlots)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.xs)
        .background(
            Theme.Palette.surface
                .overlay(Theme.Palette.hairline.frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Helpers

    private static func upcomingDays(count: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
}

// MARK: - Day pill

private struct DayPill: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(isToday ? "TODAY" : Self.weekday(date))
                    .font(Theme.Typography.caption)
                    .tracking(0.6)
                    .foregroundStyle(
                        isSelected ? Theme.Palette.onDarkSecondary : Theme.Palette.inkSecondary
                    )
                Text(Self.dayNumber(date))
                    .font(Theme.Typography.display(24, .bold))
                    .foregroundStyle(isSelected ? Theme.Palette.onDark : Theme.Palette.ink)
                    .contentTransition(.numericText())
            }
            .frame(width: 56)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                isSelected ? Theme.Palette.primary : Theme.Palette.surface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(Theme.Palette.hairline, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PressScaleStyle())
    }

    private static func weekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }

    private static func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}

// MARK: - Tee-time row

/// Full-width editorial tee-time row: a big time number leads, price and remaining
/// spots trail. Prime / limited slots (2 or fewer left) get the living green
/// `BrandGradientDrift` texture; sold-out slots are dimmed and disabled.
private struct TeeTimeRow: View {
    let teeTime: TeeTime
    let isSelected: Bool
    let action: () -> Void

    private var isPrime: Bool { !teeTime.isSoldOut && teeTime.spotsLeft <= 2 }
    private var onDark: Bool { isSelected || isPrime }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                // Big time number + tiny meridiem
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxs) {
                    Text(clockText)
                        .font(Theme.Typography.display(32, .bold))
                        .foregroundStyle(timeColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.numericText())
                    Text(meridiemText)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(meridiemColor)
                }

                Spacer(minLength: 0)

                // Price + remaining spots
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("$")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(priceUnitColor)
                        Text("\(teeTime.price)")
                            .font(Theme.Typography.display(20, .semibold))
                            .foregroundStyle(priceColor)
                            .contentTransition(.numericText())
                    }
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(subtitleColor)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .opacity(teeTime.isSoldOut ? 0.5 : 1)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(teeTime.isSoldOut)
    }

    // MARK: Time parsing ("9:00 AM" -> "9:00" + "AM")

    private var clockText: String {
        let parts = teeTime.timeDisplay.split(separator: " ")
        return parts.first.map(String.init) ?? teeTime.timeDisplay
    }

    private var meridiemText: String {
        let parts = teeTime.timeDisplay.split(separator: " ")
        return parts.count > 1 ? String(parts[1]) : ""
    }

    private var subtitle: String {
        if teeTime.isSoldOut { return "Sold out" }
        if isPrime { return teeTime.spotsLeft == 1 ? "1 left" : "\(teeTime.spotsLeft) left" }
        return "\(teeTime.spotsLeft) left"
    }

    // MARK: Styling

    @ViewBuilder
    private var background: some View {
        if isSelected {
            Theme.Palette.primary
        } else if isPrime {
            BrandGradientDrift()
        } else {
            Theme.Palette.surface
        }
    }

    private var borderColor: Color {
        if isSelected { return Theme.Palette.primary }
        if isPrime { return .clear }
        return Theme.Palette.hairline
    }

    private var timeColor: Color {
        if teeTime.isSoldOut { return Theme.Palette.inkTertiary }
        return onDark ? Theme.Palette.onDark : Theme.Palette.ink
    }

    private var meridiemColor: Color {
        if teeTime.isSoldOut { return Theme.Palette.inkTertiary }
        return onDark ? Theme.Palette.onDarkSecondary : Theme.Palette.inkSecondary
    }

    private var priceColor: Color {
        if teeTime.isSoldOut { return Theme.Palette.inkTertiary }
        return onDark ? Theme.Palette.onDark : Theme.Palette.ink
    }

    private var priceUnitColor: Color {
        if teeTime.isSoldOut { return Theme.Palette.inkTertiary }
        return onDark ? Theme.Palette.onDarkSecondary : Theme.Palette.inkSecondary
    }

    private var subtitleColor: Color {
        if teeTime.isSoldOut { return Theme.Palette.inkTertiary }
        return onDark ? Theme.Palette.onDarkSecondary : Theme.Palette.inkTertiary
    }
}

#Preview {
    NavigationStack {
        BookSlotsView()
    }
    .environment(AppState())
}
