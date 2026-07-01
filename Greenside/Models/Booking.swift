import Foundation

/// An optional extra a player can add during checkout (book step 3).
struct AddOn: Identifiable, Hashable {
    let id: UUID
    var title: String
    var subtitle: String
    var systemImage: String
    /// Price in whole US dollars (applied once per booking).
    var price: Int

    init(id: UUID = UUID(), title: String, subtitle: String, systemImage: String, price: Int) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.price = price
    }

    /// Default add-ons offered at checkout.
    static let defaults: [AddOn] = [
        AddOn(title: "Cart rental", subtitle: "Skip the walk", systemImage: "car.fill", price: 40),
        AddOn(title: "Club rental", subtitle: "Premium set", systemImage: "figure.golf", price: 65),
        AddOn(title: "Range balls", subtitle: "Warm up first", systemImage: "circle.grid.3x3.fill", price: 15),
    ]
}

/// A completed or in-progress booking. Money is tracked in whole dollars.
struct Booking: Identifiable, Hashable {
    let id: UUID
    var course: Course
    var date: Date
    var teeTime: TeeTime
    var players: Int
    var addOns: [AddOn]
    var confirmationCode: String

    init(
        id: UUID = UUID(),
        course: Course,
        date: Date,
        teeTime: TeeTime,
        players: Int,
        addOns: [AddOn] = [],
        confirmationCode: String = ""
    ) {
        self.id = id
        self.course = course
        self.date = date
        self.teeTime = teeTime
        self.players = players
        self.addOns = addOns
        self.confirmationCode = confirmationCode
    }

    // MARK: - Pricing

    /// Green fees × number of players.
    var greenFeesTotal: Int { teeTime.price * players }
    /// Sum of selected add-ons.
    var addOnsTotal: Int { addOns.reduce(0) { $0 + $1.price } }
    /// Flat booking/service fee.
    var serviceFee: Int { 12 }
    /// Estimated taxes (~8% of fees + add-ons), rounded.
    var taxes: Int { Int((Double(greenFeesTotal + addOnsTotal) * 0.08).rounded()) }
    /// Grand total charged.
    var total: Int { greenFeesTotal + addOnsTotal + serviceFee + taxes }

    var dateDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}
