import Foundation

/// In-memory implementation of `GreensideService` backed by `SampleData`.
/// Adds a tiny artificial delay so loading states behave like a real API.
/// Bookings created during a session are appended to `myRounds`.
actor MockGreensideService: GreensideService {

    private var courses: [Course] = SampleData.courses
    private var user: UserProfile = SampleData.joe
    private var activity: [LoyaltyActivity] = SampleData.loyaltyActivity
    private var upcoming: Booking? = SampleData.nextRound
    private var rounds: [Booking] = [SampleData.nextRound] + SampleData.pastRounds

    /// Simulated network latency.
    private var latency: Duration = .milliseconds(250)

    private func simulateLatency() async {
        try? await Task.sleep(for: latency)
    }

    func fetchCourses() async -> [Course] {
        await simulateLatency()
        return courses
    }

    func fetchRecommended() async -> [Course] {
        await simulateLatency()
        return courses.sorted { $0.rating > $1.rating }
    }

    func course(id: UUID) async -> Course? {
        courses.first { $0.id == id }
    }

    func searchCourses(query: String, filters: Set<CourseFilter>) async -> [Course] {
        await simulateLatency()
        var results = courses

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            results = results.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed)
                    || $0.location.localizedCaseInsensitiveContains(trimmed)
            }
        }

        for filter in filters {
            switch filter {
            case .hotDeals:
                results = results.filter(\.isHotDeal)
            case .nearby:
                results = results.filter { $0.distanceMiles <= 6 }
            case .topRated:
                results = results.filter { $0.rating >= 4.8 }
            case .availableToday:
                results = results.filter { $0.slotsAvailableToday > 0 }
            case .underHundred:
                results = results.filter { $0.greenFee < 100 }
            case .championship:
                results = results.filter { $0.tags.contains(.championship) }
            }
        }

        return results
    }

    func availability(courseID: UUID, date: Date) async -> [Slot] {
        await simulateLatency()
        guard let course = courses.first(where: { $0.id == courseID }) else { return [] }
        return SampleData.availability(for: course, on: date)
    }

    func currentUser() async -> UserProfile {
        user
    }

    func loyaltyActivity() async -> [LoyaltyActivity] {
        activity
    }

    func nextRound() async -> Booking? {
        upcoming
    }

    func myRounds() async -> [Booking] {
        rounds.sorted { $0.date > $1.date }
    }

    @discardableResult
    func createBooking(_ booking: Booking) async -> Booking {
        await simulateLatency()
        var confirmed = booking
        if confirmed.confirmationCode.isEmpty {
            confirmed.confirmationCode = Self.makeConfirmationCode()
        }
        rounds.append(confirmed)
        upcoming = confirmed
        // Earn loyalty points for the booking.
        let earned = max(50, confirmed.total / 10)
        activity.insert(
            LoyaltyActivity(
                title: "Booked \(confirmed.course.name)",
                date: Date(),
                points: earned,
                systemImage: "calendar.badge.plus"
            ),
            at: 0
        )
        user.points += earned
        user.pointsToNextTier = max(0, user.pointsToNextTier - earned)
        return confirmed
    }

    private static func makeConfirmationCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let suffix = String((0..<5).map { _ in chars.randomElement()! })
        return "GS-\(suffix)"
    }
}
