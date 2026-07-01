import UIKit

/// Lightweight haptic feedback helpers used across the app for key interactions
/// (selecting a tee time, toggling, confirming a booking).
enum Haptics {
    /// A light tap — buttons, card taps.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// A firmer tap — committing an action.
    static func impact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// A selection tick — choosing among options (tee times, filters, add-ons).
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A success notification — booking confirmed.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
