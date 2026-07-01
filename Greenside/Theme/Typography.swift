import SwiftUI
import UIKit

/// Typography for Greenside.
///
/// The Figma design uses two custom typefaces:
///   • **Funnel Display** — bold display headings ("Greenside", "Good morning")
///   • **Funnel Sans**     — body copy, buttons, labels
///
/// These are Google Fonts (Open Font License). Until the `.ttf` files are added
/// to `Theme/Fonts` and registered via `UIAppFonts`, every call here transparently
/// falls back to the system font at the equivalent weight, so the app builds and
/// looks reasonable immediately. Drop the fonts in and the correct faces light up
/// with no code changes. See `Theme/Fonts/README.md`.
extension Theme {

    enum FontName {
        static let displayBold = "FunnelDisplay-Bold"
        static let displaySemibold = "FunnelDisplay-SemiBold"
        static let displayMedium = "FunnelDisplay-Medium"
        static let sansRegular = "FunnelSans-Regular"
        static let sansMedium = "FunnelSans-Medium"
        static let sansSemibold = "FunnelSans-SemiBold"
        static let sansBold = "FunnelSans-Bold"
    }

    /// Named text styles pulled from the Figma type scale.
    enum Typography {
        /// Funnel Display Bold 46 — Welcome hero title.
        static var welcome: Font { display(46, .bold) }
        /// Funnel Display Bold 30 — greetings, screen titles.
        static var largeTitle: Font { display(30, .bold) }
        /// Funnel Display Bold 26 — hero card titles (course name).
        static var titleHero: Font { display(26, .bold) }
        /// Funnel Display Bold 22 — section headers.
        static var title: Font { display(22, .bold) }
        /// Funnel Display Bold 20.
        static var title2: Font { display(20, .bold) }

        /// Funnel Sans SemiBold 17 — card titles, list rows.
        static var headline: Font { text(17, .semibold) }
        /// Funnel Sans Regular 16 — body copy.
        static var body: Font { text(16, .regular) }
        /// Funnel Sans Medium 16.
        static var bodyMedium: Font { text(16, .medium) }
        /// Funnel Sans SemiBold 15.5 — buttons.
        static var button: Font { text(15.5, .semibold) }
        /// Funnel Sans Medium 14 — supporting labels.
        static var callout: Font { text(14, .medium) }
        /// Funnel Sans Regular 13 — captions, metadata.
        static var footnote: Font { text(13, .regular) }
        /// Funnel Sans SemiBold 12 — badges, uppercase eyebrows.
        static var caption: Font { text(12, .semibold) }

        // MARK: Factories

        /// A Funnel Display font at the given size/weight, falling back to the
        /// rounded system serif-free display face if unavailable.
        static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
            custom(displayName(for: weight), size: size, fallbackWeight: weight)
        }

        /// A Funnel Sans font at the given size/weight, falling back to the
        /// system font if unavailable.
        static func text(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
            custom(sansName(for: weight), size: size, fallbackWeight: weight)
        }

        private static func custom(_ name: String, size: CGFloat, fallbackWeight: Font.Weight) -> Font {
            FontAvailability.isRegistered(name)
                ? .custom(name, size: size)
                : .system(size: size, weight: fallbackWeight)
        }

        private static func displayName(for weight: Font.Weight) -> String {
            switch weight {
            case .medium, .regular: return FontName.displayMedium
            case .semibold: return FontName.displaySemibold
            default: return FontName.displayBold
            }
        }

        private static func sansName(for weight: Font.Weight) -> String {
            switch weight {
            case .bold, .heavy, .black: return FontName.sansBold
            case .semibold: return FontName.sansSemibold
            case .medium: return FontName.sansMedium
            default: return FontName.sansRegular
            }
        }
    }
}

/// Caches whether a named font is actually registered so we only probe UIKit once.
private enum FontAvailability {
    private static var cache: [String: Bool] = [:]

    static func isRegistered(_ name: String) -> Bool {
        if let cached = cache[name] { return cached }
        let available = UIFont(name: name, size: 12) != nil
        cache[name] = available
        return available
    }
}
