import SwiftUI

extension Color {
    /// Create a color from a 0xRRGGBB hex literal, e.g. `Color(hex: 0x1E4733)`.
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
