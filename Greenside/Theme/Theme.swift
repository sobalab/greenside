import SwiftUI

/// Central design system for Greenside, derived from the Figma source
/// (file GdiAvbgtAvGvVguHvzR9um). Screens should reference these tokens
/// rather than hardcoding colors, fonts, spacing, or radii so styling
/// stays consistent as we build screen-by-screen.
enum Theme {

    // MARK: - Colors

    enum Palette {
        /// Brand forest green — primary brand color, dark surfaces, key text accents.
        static let primary = Color(hex: 0x1E4733)
        /// A deeper green used for pressed states / gradient anchoring.
        static let primaryDeep = Color(hex: 0x143528)
        /// Warm off-white app background.
        static let background = Color(hex: 0xF3F3EF)
        /// White card / sheet surface.
        static let surface = Color.white
        /// A very subtly tinted surface for nested fills.
        static let surfaceMuted = Color(hex: 0xECEBE4)

        /// Primary text on light backgrounds (near-black with a green cast).
        static let ink = Color(hex: 0x1A2620)
        /// Secondary / supporting text.
        static let inkSecondary = Color(hex: 0x77837B)
        /// Tertiary text, placeholders, disabled.
        static let inkTertiary = Color(hex: 0x9AA39C)

        /// Text/icons on dark (green) surfaces.
        static let onDark = Color.white
        /// Secondary text on dark surfaces (matches Figma rgba(255,255,255,0.62)).
        static let onDarkSecondary = Color.white.opacity(0.62)

        /// Medium green used for links ("See all") and inline accents.
        static let accent = Color(hex: 0x2E7D57)
        /// Lime highlight pulled from the brand gradient.
        static let lime = Color(hex: 0x8FD46A)

        /// Hairline separators / borders.
        static let hairline = Color(hex: 0xE7E7E1)
        /// Rating star tint.
        static let star = Color(hex: 0xE9A23B)

        /// The four-stop brand gradient (welcome CTA, hero accents).
        static let gradientStops = [
            Color(hex: 0x2A6B54),
            Color(hex: 0x2EC494),
            Color(hex: 0x8FD46A),
            Color(hex: 0xD9E55C),
        ]
    }

    /// Signature diagonal brand gradient (matches the Figma 146° angle).
    static let brandGradient = LinearGradient(
        colors: Palette.gradientStops,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Spacing (4pt base scale)

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }

    /// Default horizontal inset for standard screens.
    static let screenPadding: CGFloat = 20

    // MARK: - Corner radius

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        /// Fully rounded (pills, chips, price tags).
        static let pill: CGFloat = 999
    }

    // MARK: - Shadow

    enum Shadow {
        static let card = (color: Color.black.opacity(0.06), radius: CGFloat(14), y: CGFloat(6))
    }
}
