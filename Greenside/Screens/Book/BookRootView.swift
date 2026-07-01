import SwiftUI

/// Root of the Book tab. Owns the wizard's `NavigationStack`, binding it to the
/// shared booking view model's path so the flow (slots → confirm profile →
/// review & pay → confirmation) is fully driven by `appState.booking`.
struct BookRootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var booking = appState.booking

        NavigationStack(path: $booking.path) {
            BookSlotsView()
                .navigationDestination(for: BookingRoute.self) { route in
                    switch route {
                    case .confirmProfile:
                        ConfirmProfileView()
                    case .reviewAndPay:
                        ReviewAndPayView()
                    case .confirmation:
                        ConfirmationView()
                    }
                }
        }
    }
}

#Preview {
    BookRootView()
        .environment(AppState())
}
