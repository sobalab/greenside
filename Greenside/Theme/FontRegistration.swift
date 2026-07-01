import CoreText
import Foundation

/// Registers the bundled static Funnel fonts with the process at launch so
/// `UIFont(name:)` and `Font.custom` resolve them.
///
/// The project auto-generates its Info.plist (no `UIAppFonts` array), so we
/// register the faces at runtime instead. Called once from `GreensideApp.init`.
enum FontRegistration {
    private static let faces = [
        "FunnelDisplay-Regular",
        "FunnelDisplay-Medium",
        "FunnelDisplay-SemiBold",
        "FunnelDisplay-Bold",
        "FunnelSans-Regular",
        "FunnelSans-Medium",
        "FunnelSans-SemiBold",
        "FunnelSans-Bold",
    ]

    static func registerAll() {
        for face in faces {
            guard let url = Bundle.main.url(forResource: face, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
