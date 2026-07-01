import Foundation

/// Time-of-day grouping used by the booking slot grid.
enum DayPeriod: String, CaseIterable, Identifiable, Hashable {
    case morning = "Morning"
    case afternoon = "Afternoon"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        }
    }
}

/// A single bookable tee time on a given day.
struct TeeTime: Identifiable, Hashable {
    let id: UUID
    /// The scheduled moment (day + time) of this tee time.
    var start: Date
    var period: DayPeriod
    /// Price per player in whole US dollars for this specific time.
    var price: Int
    /// Remaining spots (drives the "N left" badge). 0 = sold out.
    var spotsLeft: Int

    init(id: UUID = UUID(), start: Date, period: DayPeriod, price: Int, spotsLeft: Int) {
        self.id = id
        self.start = start
        self.period = period
        self.price = price
        self.spotsLeft = spotsLeft
    }

    var isSoldOut: Bool { spotsLeft <= 0 }

    var timeDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: start)
    }
}

/// Availability for one period of a day — a section in the slot grid.
struct Slot: Identifiable, Hashable {
    let id: UUID
    var period: DayPeriod
    var teeTimes: [TeeTime]

    init(id: UUID = UUID(), period: DayPeriod, teeTimes: [TeeTime]) {
        self.id = id
        self.period = period
        self.teeTimes = teeTimes
    }
}
