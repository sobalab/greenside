import Foundation

/// Filters available on the Browse screen (rendered as chips).
enum CourseFilter: String, CaseIterable, Identifiable, Hashable {
    case hotDeals = "Hot deals"
    case nearby = "Nearby"
    case topRated = "Top rated"
    case availableToday = "Available today"
    case underHundred = "Under $100"
    case championship = "Championship"

    var id: String { rawValue }
}

/// Abstraction over the Greenside backend. The app talks only to this protocol,
/// so `MockGreensideService` can be swapped for a real networked implementation
/// later without touching view models or views.
protocol GreensideService {
    /// All courses in the catalog.
    func fetchCourses() async -> [Course]
    /// Courses recommended for the Home "Recommended near you" row.
    func fetchRecommended() async -> [Course]
    /// Courses the user has hearted (Book tab "Your favorites").
    func favoriteCourses() async -> [Course]
    /// Look up a single course by id.
    func course(id: UUID) async -> Course?
    /// Search + filter the catalog.
    func searchCourses(query: String, filters: Set<CourseFilter>) async -> [Course]
    /// Available tee times for a course on a given day, grouped by period.
    func availability(courseID: UUID, date: Date) async -> [Slot]

    /// The signed-in user.
    func currentUser() async -> UserProfile
    /// The user's loyalty activity feed.
    func loyaltyActivity() async -> [LoyaltyActivity]
    /// The user's upcoming round for the Home "Your next round" card, if any.
    func nextRound() async -> Booking?
    /// The user's recent/past bookings ("My Rounds").
    func myRounds() async -> [Booking]

    /// Persist a booking and return it stamped with a confirmation code.
    @discardableResult
    func createBooking(_ booking: Booking) async -> Booking
}
