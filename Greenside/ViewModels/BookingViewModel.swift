import Foundation
import Observation

/// Steps pushed onto the booking `NavigationStack`. Step 1 is the stack root,
/// so the routes here are steps 2, 3, and the confirmation screen.
enum BookingRoute: Hashable {
    case confirmProfile   // Book step 2
    case reviewAndPay     // Book step 3
    case confirmation     // Confirmation
}

/// Single source of truth for an in-progress booking. One instance is shared
/// across all three wizard steps so the selected course, date, tee time, player
/// count, add-ons, and profile persist as the user moves forward and back.
@MainActor
@Observable
final class BookingViewModel {

    // MARK: Navigation
    var path: [BookingRoute] = []

    // MARK: Selection state
    var course: Course?
    var date: Date = Calendar.current.startOfDay(for: Date())
    var slots: [Slot] = []
    var selectedTeeTime: TeeTime?
    var players: Int = 1
    var selectedAddOnIDs: Set<UUID> = []
    var addOns: [AddOn] = AddOn.defaults

    /// Editable copy of the user's profile confirmed on step 2.
    var profile: UserProfile?

    /// The finalized booking, set once `confirm()` succeeds.
    private(set) var confirmedBooking: Booking?

    var isLoadingSlots = false
    var isProcessingPayment = false

    private let service: GreensideService

    init(service: GreensideService) {
        self.service = service
    }

    // MARK: - Lifecycle

    /// Begin a fresh booking for a course.
    func start(course: Course) {
        self.course = course
        self.date = Calendar.current.startOfDay(for: Date())
        self.selectedTeeTime = nil
        self.players = 1
        self.selectedAddOnIDs = []
        self.confirmedBooking = nil
        self.path = []
    }

    func loadProfileIfNeeded() async {
        guard profile == nil else { return }
        profile = await service.currentUser()
    }

    func loadAvailability() async {
        guard let course else { return }
        isLoadingSlots = true
        defer { isLoadingSlots = false }
        slots = await service.availability(courseID: course.id, date: date)
        // Clear a selection that no longer exists for the new date.
        if let selected = selectedTeeTime,
           !slots.flatMap(\.teeTimes).contains(where: { $0.id == selected.id }) {
            selectedTeeTime = nil
        }
    }

    // MARK: - Mutations

    func selectDate(_ newDate: Date) async {
        date = Calendar.current.startOfDay(for: newDate)
        await loadAvailability()
    }

    func select(teeTime: TeeTime) {
        selectedTeeTime = teeTime.isSoldOut ? nil : teeTime
    }

    func incrementPlayers() { players = min(players + 1, min(4, selectedSpotsCeiling)) }
    func decrementPlayers() { players = max(1, players - 1) }

    private var selectedSpotsCeiling: Int {
        selectedTeeTime?.spotsLeft ?? 4
    }

    func toggleAddOn(_ addOn: AddOn) {
        if selectedAddOnIDs.contains(addOn.id) {
            selectedAddOnIDs.remove(addOn.id)
        } else {
            selectedAddOnIDs.insert(addOn.id)
        }
    }

    func isSelected(_ addOn: AddOn) -> Bool { selectedAddOnIDs.contains(addOn.id) }

    // MARK: - Derived

    var selectedAddOns: [AddOn] { addOns.filter { selectedAddOnIDs.contains($0.id) } }

    /// A draft booking reflecting current selections (nil until a tee time is chosen).
    var draft: Booking? {
        guard let course, let selectedTeeTime else { return nil }
        return Booking(
            course: course,
            date: date,
            teeTime: selectedTeeTime,
            players: players,
            addOns: selectedAddOns
        )
    }

    var canContinueFromSlots: Bool { selectedTeeTime != nil }

    // MARK: - Navigation intents

    func goToConfirmProfile() { path.append(.confirmProfile) }
    func goToReviewAndPay() { path.append(.reviewAndPay) }

    /// Stub "Pay" — no real payment. Persists the booking and advances to confirmation.
    func confirmAndPay() async {
        guard let draft else { return }
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        let booking = await service.createBooking(draft)
        confirmedBooking = booking
        path.append(.confirmation)
    }

    /// Reset back to the empty Book tab (used by "Done" on confirmation).
    func reset() {
        course = nil
        selectedTeeTime = nil
        confirmedBooking = nil
        path = []
    }
}
