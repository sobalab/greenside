import SwiftUI

/// The **Tee sheet** — Birdie style. Pick a date from a row of pills, then tap a
/// tee time (limited ones wear the living dawn gradient) to open the Booking
/// sheet. Root content inside `BookRootView`'s NavigationStack.
struct BookSlotsView: View {
    @Environment(AppState.self) private var appState
    @State private var showBooking = false

    var body: some View {
        @Bindable var booking = appState.booking

        Group {
            if booking.course == nil {
                emptyState
            } else {
                content(booking: booking)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .task {
            await booking.loadProfileIfNeeded()
            if booking.slots.isEmpty {
                await booking.loadAvailability()
            }
        }
        .sheet(isPresented: $showBooking) {
            BookingSheetView()
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "flag.fill")
                .font(.system(size: 46))
                .foregroundStyle(Theme.Palette.muted)
            VStack(spacing: 8) {
                Text("Pick a course to book")
                    .font(.display(28, .bold))
                    .foregroundStyle(Theme.Palette.charcoal)
                    .multilineTextAlignment(.center)
                Text("Browse our courses and start a round.")
                    .font(.body(16, .regular))
                    .foregroundStyle(Theme.Palette.muted)
                    .multilineTextAlignment(.center)
            }
            PillButton(title: "Browse courses", style: .volt) {
                appState.selectedTab = .browse
            }
            .padding(.top, 4)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(booking: BookingViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let course = booking.course {
                    header(course)
                }

                dateStrip(booking: booking)

                availability(booking: booking)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    private func header(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tee sheet")
                .font(.body(12, .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.muted)
            HStack(spacing: 14) {
                CourseImage(course: course)
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.name)
                        .font(.display(30, .bold))
                        .foregroundStyle(Theme.Palette.charcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(course.location)
                        .font(.body(13, .regular))
                        .foregroundStyle(Theme.Palette.muted)
                }
            }
        }
    }

    // MARK: - Date strip

    private func dateStrip(booking: BookingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select a date")
                .font(.body(12, .semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Self.days(), id: \.self) { day in
                        DatePill(
                            date: day,
                            isSelected: Calendar.current.isDate(booking.date, inSameDayAs: day),
                            isToday: Calendar.current.isDateInToday(day)
                        ) {
                            Haptics.selection()
                            Task { await booking.selectDate(day) }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    // MARK: - Availability

    @ViewBuilder
    private func availability(booking: BookingViewModel) -> some View {
        if booking.isLoadingSlots {
            VStack(spacing: 10) {
                ProgressView().tint(Theme.Palette.charcoal)
                Text("Finding open tee times…")
                    .font(.body(13, .medium))
                    .foregroundStyle(Theme.Palette.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        } else if booking.slots.allSatisfy({ $0.teeTimes.isEmpty }) {
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.Palette.muted)
                Text("No tee times this day")
                    .font(.display(20, .bold))
                    .foregroundStyle(Theme.Palette.charcoal)
                Text("Try another date above.")
                    .font(.body(14, .regular))
                    .foregroundStyle(Theme.Palette.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            ForEach(booking.slots) { slot in
                if !slot.teeTimes.isEmpty {
                    periodSection(slot: slot, booking: booking)
                }
            }
        }
    }

    private func periodSection(slot: Slot, booking: BookingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: slot.period.systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Palette.charcoal)
                Text(slot.period.rawValue)
                    .font(.body(12, .semibold))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Palette.charcoal)
                Spacer()
                Text("\(slot.teeTimes.filter { !$0.isSoldOut }.count) open")
                    .font(.body(13, .medium))
                    .foregroundStyle(Theme.Palette.muted)
            }

            VStack(spacing: 10) {
                ForEach(slot.teeTimes) { teeTime in
                    let parts = Self.split(teeTime)
                    TeeSlotRow(
                        time: parts.0,
                        meridiem: parts.1,
                        price: teeTime.price,
                        spotsLeft: teeTime.spotsLeft,
                        isPrime: !teeTime.isSoldOut && teeTime.spotsLeft <= 2
                    ) {
                        guard !teeTime.isSoldOut else { return }
                        booking.select(teeTime: teeTime)
                        showBooking = true
                    }
                    .opacity(teeTime.isSoldOut ? 0.5 : 1)
                }
            }
        }
    }

    // MARK: - Helpers

    private static func days() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<10).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    private static func split(_ tee: TeeTime) -> (String, String) {
        let parts = tee.timeDisplay.split(separator: " ")
        return (String(parts.first ?? ""), String(parts.count > 1 ? parts[1] : ""))
    }
}

// MARK: - Date pill

private struct DatePill: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(isToday ? "TODAY" : Self.weekday(date))
                    .font(.body(11, .semibold))
                    .tracking(0.5)
                    .foregroundStyle(isSelected ? Theme.Palette.paper.opacity(0.75) : Theme.Palette.muted)
                Text(Self.day(date))
                    .font(.display(22, .bold))
                    .foregroundStyle(isSelected ? Theme.Palette.paper : Theme.Palette.charcoal)
                    .contentTransition(.numericText())
            }
            .frame(width: 58)
            .padding(.vertical, 14)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.Palette.charcoal)
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.Palette.paper)
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.Palette.mist, lineWidth: 1))
                }
            }
        }
        .buttonStyle(PressScaleStyle())
    }

    private static func weekday(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: d).uppercased()
    }
    private static func day(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: d)
    }
}

#Preview {
    NavigationStack { BookSlotsView() }
        .environment(AppState())
}
