import Foundation

/// Seed data matching the Figma design: five marquee courses, golfer Joe Bradley,
/// a Level 2 "Birdie" loyalty status, and an upcoming round at Bethpage Black.
enum SampleData {

    // MARK: - Helpers

    private static let calendar = Calendar(identifier: .gregorian)

    private static func date(daysFromNow days: Int, hour: Int = 9, minute: Int = 0) -> Date {
        let base = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
    }

    // MARK: - Courses

    static let pebbleBeach = Course(
        id: UUID(),
        name: "Pebble Beach",
        location: "Pebble Beach, CA",
        par: 72,
        holes: 18,
        lengthYards: 6828,
        designer: "Jack Neville & Douglas Grant",
        rating: 4.9,
        reviewCount: 1284,
        greenFee: 595,
        distanceMiles: 2.4,
        slotsAvailableToday: 6,
        imageName: "course_pebble_beach",
        about: "Perched on the rugged cliffs of the Monterey Peninsula, Pebble Beach is one of golf's most iconic tests. Ocean holes, tiny greens, and Pacific wind make every round unforgettable.",
        facilities: [
            Facility(name: "Pro shop", systemImage: "bag.fill"),
            Facility(name: "Driving range", systemImage: "figure.golf"),
            Facility(name: "Restaurant", systemImage: "fork.knife"),
            Facility(name: "Club rental", systemImage: "briefcase.fill"),
            Facility(name: "Caddies", systemImage: "figure.walk"),
            Facility(name: "Valet", systemImage: "car.fill"),
        ],
        reviews: [
            Review(authorName: "Marcus T.", rating: 5, date: date(daysFromNow: -6),
                   text: "Bucket-list round. The 7th and 18th are worth every penny."),
            Review(authorName: "Dana W.", rating: 5, date: date(daysFromNow: -21),
                   text: "Immaculate conditions and staff that treats you like a member."),
        ],
        tags: [.links, .championship, .resort]
    )

    static let augustaNational = Course(
        id: UUID(),
        name: "Augusta National",
        location: "Augusta, GA",
        par: 72,
        holes: 18,
        lengthYards: 7475,
        designer: "Alister MacKenzie & Bobby Jones",
        rating: 4.8,
        reviewCount: 902,
        greenFee: 340,
        distanceMiles: 5.1,
        slotsAvailableToday: 3,
        imageName: "course_augusta",
        about: "Home of the Masters. Sweeping elevation changes, lightning-fast greens, and Amen Corner make this the most storied parkland course in the game.",
        facilities: [
            Facility(name: "Pro shop", systemImage: "bag.fill"),
            Facility(name: "Driving range", systemImage: "figure.golf"),
            Facility(name: "Restaurant", systemImage: "fork.knife"),
            Facility(name: "Caddies", systemImage: "figure.walk"),
            Facility(name: "Locker room", systemImage: "lock.fill"),
        ],
        reviews: [
            Review(authorName: "Priya S.", rating: 5, date: date(daysFromNow: -3),
                   text: "Every hole is a painting. Greens are unreal in person."),
            Review(authorName: "Leo K.", rating: 4, date: date(daysFromNow: -14),
                   text: "Tough but fair. Bring your best short game to Amen Corner."),
        ],
        tags: [.parkland, .championship]
    )

    static let tpcSawgrass = Course(
        id: UUID(),
        name: "TPC Sawgrass",
        location: "Ponte Vedra Beach, FL",
        par: 72,
        holes: 18,
        lengthYards: 7245,
        designer: "Pete Dye",
        rating: 4.7,
        reviewCount: 771,
        greenFee: 415,
        distanceMiles: 8.7,
        slotsAvailableToday: 8,
        imageName: "course_sawgrass",
        about: "The Stadium Course and its infamous island green 17th. A Pete Dye masterpiece that rewards precision over power.",
        facilities: [
            Facility(name: "Pro shop", systemImage: "bag.fill"),
            Facility(name: "Driving range", systemImage: "figure.golf"),
            Facility(name: "Restaurant", systemImage: "fork.knife"),
            Facility(name: "Club rental", systemImage: "briefcase.fill"),
            Facility(name: "Cart", systemImage: "car.fill"),
        ],
        reviews: [
            Review(authorName: "Sofia R.", rating: 5, date: date(daysFromNow: -2),
                   text: "Hit the green on 17 and I've never felt more alive."),
        ],
        tags: [.championship, .publicAccess]
    )

    static let pinehurst = Course(
        id: UUID(),
        name: "Pinehurst No. 2",
        location: "Pinehurst, NC",
        par: 70,
        holes: 18,
        lengthYards: 7588,
        designer: "Donald Ross",
        rating: 4.8,
        reviewCount: 640,
        greenFee: 385,
        distanceMiles: 12.3,
        slotsAvailableToday: 5,
        imageName: "course_pinehurst",
        about: "Donald Ross's crowning achievement, famous for its turtleback greens that repel anything but a perfect approach. Multiple-time U.S. Open host.",
        facilities: [
            Facility(name: "Pro shop", systemImage: "bag.fill"),
            Facility(name: "Driving range", systemImage: "figure.golf"),
            Facility(name: "Restaurant", systemImage: "fork.knife"),
            Facility(name: "Caddies", systemImage: "figure.walk"),
            Facility(name: "Locker room", systemImage: "lock.fill"),
        ],
        reviews: [
            Review(authorName: "Grant M.", rating: 5, date: date(daysFromNow: -9),
                   text: "Those crowned greens will humble you. A true examination."),
        ],
        tags: [.parkland, .championship, .resort]
    )

    static let bethpageBlack = Course(
        id: UUID(),
        name: "Bethpage Black",
        location: "Farmingdale, NY",
        par: 71,
        holes: 18,
        lengthYards: 7468,
        designer: "A.W. Tillinghast",
        rating: 4.6,
        reviewCount: 1533,
        greenFee: 150,
        distanceMiles: 3.8,
        slotsAvailableToday: 4,
        imageName: "course_bethpage",
        about: "The people's championship course. A brutal, walking-only public test that has hosted the U.S. Open and the Ryder Cup. The warning sign at the first tee is no joke.",
        facilities: [
            Facility(name: "Pro shop", systemImage: "bag.fill"),
            Facility(name: "Driving range", systemImage: "figure.golf"),
            Facility(name: "Restaurant", systemImage: "fork.knife"),
            Facility(name: "Walking only", systemImage: "figure.walk"),
        ],
        reviews: [
            Review(authorName: "Joe B.", rating: 5, date: date(daysFromNow: -30),
                   text: "The best public course in America, full stop. Book it and walk it."),
            Review(authorName: "Nina P.", rating: 4, date: date(daysFromNow: -18),
                   text: "Long and demanding. Bring extra balls and a caddie's patience."),
        ],
        tags: [.publicAccess, .championship, .walkingOnly]
    )

    static let courses: [Course] = [
        pebbleBeach, augustaNational, tpcSawgrass, pinehurst, bethpageBlack,
    ]

    // MARK: - User

    static let joe = UserProfile(
        firstName: "Joe",
        lastName: "Bradley",
        email: "joe.bradley@example.com",
        phone: "(917) 555-0142",
        handicap: 11.4,
        avatarImageName: "avatar_joe",
        memberSince: date(daysFromNow: -540),
        loyaltyLevel: 2,
        loyaltyTier: "Birdie",
        points: 1250,
        pointsToNextTier: 750
    )

    static let loyaltyActivity: [LoyaltyActivity] = [
        LoyaltyActivity(title: "Booked Bethpage Black", date: date(daysFromNow: -1),
                        points: 120, systemImage: "calendar.badge.plus"),
        LoyaltyActivity(title: "Reviewed Pebble Beach", date: date(daysFromNow: -6),
                        points: 40, systemImage: "star.fill"),
        LoyaltyActivity(title: "Referred a friend", date: date(daysFromNow: -12),
                        points: 250, systemImage: "person.2.fill"),
        LoyaltyActivity(title: "Redeemed range voucher", date: date(daysFromNow: -20),
                        points: -100, systemImage: "gift.fill"),
    ]

    // MARK: - Next round (matches the Home hero card)

    static let nextRound = Booking(
        course: bethpageBlack,
        date: date(daysFromNow: 14, hour: 14, minute: 30),
        teeTime: TeeTime(
            start: date(daysFromNow: 14, hour: 14, minute: 30),
            period: .afternoon,
            price: 150,
            spotsLeft: 4
        ),
        players: 2,
        addOns: [],
        confirmationCode: "GS-8H2K9"
    )

    // MARK: - Availability

    /// Generates a plausible morning/afternoon slot grid for a course on a date.
    static func availability(for course: Course, on date: Date) -> [Slot] {
        // Hours are in 24-hour form so afternoon times map cleanly.
        let morningTimes: [(Int, Int)] = [(7, 0), (7, 40), (8, 20), (9, 0), (9, 40), (10, 20)]
        let afternoonTimes: [(Int, Int)] = [(12, 20), (13, 0), (13, 40), (14, 30), (15, 10), (16, 0)]
        let spotsPool = [4, 2, 3, 1, 4, 2, 3, 2, 4, 1, 3, 2]

        func makeTimes(_ times: [(Int, Int)], period: DayPeriod) -> [TeeTime] {
            times.enumerated().map { index, hm in
                let start = calendar.date(bySettingHour: hm.0, minute: hm.1, second: 0, of: date) ?? date
                let priceJitter = (index % 3) * 10
                return TeeTime(
                    start: start,
                    period: period,
                    price: course.greenFee + priceJitter,
                    spotsLeft: spotsPool[index % spotsPool.count]
                )
            }
        }

        return [
            Slot(period: .morning, teeTimes: makeTimes(morningTimes, period: .morning)),
            Slot(period: .afternoon, teeTimes: makeTimes(afternoonTimes, period: .afternoon)),
        ]
    }
}
