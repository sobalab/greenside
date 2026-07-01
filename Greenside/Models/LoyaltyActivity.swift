import Foundation

/// A single entry in the loyalty "recent activity" feed.
struct LoyaltyActivity: Identifiable, Hashable {
    let id: UUID
    var title: String              // "Booked Pebble Beach"
    var date: Date
    /// Points earned (+) or redeemed (-).
    var points: Int
    var systemImage: String

    init(id: UUID = UUID(), title: String, date: Date, points: Int, systemImage: String) {
        self.id = id
        self.title = title
        self.date = date
        self.points = points
        self.systemImage = systemImage
    }

    var pointsDisplay: String { points >= 0 ? "+\(points)" : "\(points)" }
    var dateDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
