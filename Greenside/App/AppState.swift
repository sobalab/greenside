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

/// App-wide state and dependency container. Holds the shared `GreensideService`
/// and hands out view models. Injected into the environment at the root.
@MainActor
@Observable
final class AppState {
    var phase: AppPhase = .main

    /// The single service instance for the whole app. Swap `MockGreensideService`
    /// for a networked implementation here and nothing else changes.
    let service: GreensideService

    /// Shared booking wizard state (lives for the app session so the Book tab
    /// keeps its progress while the user visits other tabs).
    let booking: BookingViewModel

    init(service: GreensideService = MockGreensideService()) {
        self.service = service
        self.booking = BookingViewModel(service: service)
    }

    func completeOnboarding() { phase = .main }
    func showSignIn() { phase = .signIn }
    func signOut() { phase = .welcome }
}
