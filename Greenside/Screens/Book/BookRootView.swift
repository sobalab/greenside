import SwiftUI

/// The Book tab root: hosts the Tee sheet and drives the confirmation push. The
/// player picker is presented as a sheet from the Tee sheet, so the only pushed
/// destination in the flow is the confirmation.
struct BookRootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var booking = appState.booking

        NavigationStack(path: $booking.path) {
            BookSlotsView()
                .navigationDestination(for: BookingRoute.self) { _ in
                    ConfirmationView()
                }
        }
    }
}

#Preview {
    BookRootView()
        .environment(AppState())
}
