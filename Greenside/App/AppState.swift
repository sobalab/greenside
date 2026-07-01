import Foundation
import Observation

/// Top-level app phases. The app opens on Welcome, moves through Sign in, then
/// into the main tab experience. (Wired to real Welcome/Sign-in screens next;
/// currently defaults to `.main` so the scaffold runs straight into the tabs.)
enum AppPhase {
    case welcome
    case signIn
    case main
}

/// The four main tabs. Held in `AppState` so screens can switch tabs
/// programmatically (e.g. Home's "Browse courses" action, or "Book" from a
/// course detail screen).
enum AppTab: Hashable {
    case home
    case browse
    case book
    case profile
}

/// App-wide state and dependency container. Holds the shared `GreensideService`
/// and hands out view models. Injected into the environment at the root.
@MainActor
@Observable
final class AppState {
    var phase: AppPhase = .welcome

    /// The currently-selected main tab. Screens mutate this to jump tabs.
    var selectedTab: AppTab = .home

    /// The single service instance for the whole app. Swap `MockGreensideService`
    /// for a networked implementation here and nothing else changes.
    let service: GreensideService

    /// Shared booking wizard state (lives for the app session so the Book tab
    /// keeps its progress while the user visits other tabs).
    let booking: BookingViewModel

    init(service: GreensideService = MockGreensideService()) {
        self.service = service
        self.booking = BookingViewModel(service: service)
        #if DEBUG
        applyDebugScreenOverride()
        #endif
    }

    func completeOnboarding() { phase = .main }
    func showSignIn() { phase = .signIn }
    func signOut() { phase = .welcome }

    #if DEBUG
    private func applyDebugScreenOverride() {
        guard let screen = ProcessInfo.processInfo.environment["GS_SCREEN"] else { return }
        switch screen {
        case "signin": phase = .signIn
        case "home": phase = .main; selectedTab = .home
        case "browse": phase = .main; selectedTab = .browse
        case "profile": phase = .main; selectedTab = .profile
        case "book": phase = .main; selectedTab = .book; booking.start(course: SampleData.bethpageBlack)
        case "confirm-profile":
            phase = .main; selectedTab = .book; seedFull(); booking.path = [.confirmProfile]
        case "review-pay":
            phase = .main; selectedTab = .book; seedFull(); booking.path = [.confirmProfile, .reviewAndPay]
        case "confirmation":
            phase = .main; selectedTab = .book; seedFull(); booking.path = [.confirmation]
        default: break
        }
    }

    private func seedFull() {
        booking.start(course: SampleData.bethpageBlack)
        let slots = SampleData.availability(for: SampleData.bethpageBlack, on: booking.date)
        booking.slots = slots
        booking.selectedTeeTime = slots.flatMap(\.teeTimes).first { !$0.isSoldOut }
        booking.players = 2
    }
    #endif
}
