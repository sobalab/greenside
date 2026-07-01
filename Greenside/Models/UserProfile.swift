import Foundation

/// The signed-in golfer. Editable on book step 2 and the Profile tab.
struct UserProfile: Identifiable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    /// Golf handicap index (nil if not set).
    var handicap: Double?
    /// Asset name for the avatar image.
    var avatarImageName: String
    var memberSince: Date

    // Loyalty
    var loyaltyLevel: Int          // e.g. 2
    var loyaltyTier: String        // e.g. "Birdie"
    var points: Int                // e.g. 1250
    /// Points needed to reach the next tier.
    var pointsToNextTier: Int

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        handicap: Double? = nil,
        avatarImageName: String,
        memberSince: Date,
        loyaltyLevel: Int,
        loyaltyTier: String,
        points: Int,
        pointsToNextTier: Int
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.handicap = handicap
        self.avatarImageName = avatarImageName
        self.memberSince = memberSince
        self.loyaltyLevel = loyaltyLevel
        self.loyaltyTier = loyaltyTier
        self.points = points
        self.pointsToNextTier = pointsToNextTier
    }

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased()
    }
    /// Progress toward the next loyalty tier (0...1).
    var tierProgress: Double {
        let total = points + pointsToNextTier
        guard total > 0 else { return 0 }
        return Double(points) / Double(total)
    }
}
