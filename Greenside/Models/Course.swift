import Foundation

/// A golf course that can be browsed and booked.
struct Course: Identifiable, Hashable {
    let id: UUID
    var name: String
    var location: String          // "Pebble Beach, CA"
    var par: Int
    var holes: Int
    var lengthYards: Int
    var designer: String?
    var rating: Double            // 0...5, e.g. 4.9
    var reviewCount: Int
    /// Starting green fee in whole US dollars.
    var greenFee: Int
    /// Distance from the user in miles (for "near you" sorting).
    var distanceMiles: Double
    /// How many tee times remain today (drives the "N slots" label).
    var slotsAvailableToday: Int
    /// Asset name for the hero/thumbnail image (added to the asset catalog later).
    var imageName: String
    var about: String
    var facilities: [Facility]
    var reviews: [Review]
    var tags: [CourseTag]

    var priceDisplay: String { "$\(greenFee)" }
    var ratingDisplay: String { String(format: "%.1f", rating) }
}

/// Marketing / filter tags shown as chips.
enum CourseTag: String, CaseIterable, Identifiable, Hashable {
    case links = "Links"
    case parkland = "Parkland"
    case championship = "Championship"
    case publicAccess = "Public"
    case resort = "Resort"
    case walkingOnly = "Walking"

    var id: String { rawValue }
}

/// An on-course amenity, rendered with an SF Symbol.
struct Facility: Identifiable, Hashable {
    let id: UUID
    var name: String
    var systemImage: String

    init(id: UUID = UUID(), name: String, systemImage: String) {
        self.id = id
        self.name = name
        self.systemImage = systemImage
    }
}

/// A user review shown on the course detail screen.
struct Review: Identifiable, Hashable {
    let id: UUID
    var authorName: String
    var rating: Int               // 1...5
    var date: Date
    var text: String

    init(id: UUID = UUID(), authorName: String, rating: Int, date: Date, text: String) {
        self.id = id
        self.authorName = authorName
        self.rating = rating
        self.date = date
        self.text = text
    }
}
