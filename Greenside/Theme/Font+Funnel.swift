import SwiftUI

/// Editorial type ramp for the Birdie redesign.
///
/// Headings use **Funnel Display** (big, tight); body / UI / numbers use
/// **Funnel Sans**. `relativeTo:` keeps Dynamic Type scaling working. The static
/// faces are registered at launch by `FontRegistration`.
extension Font {
    static func display(_ size: CGFloat, _ weight: DisplayWeight = .bold,
                        relativeTo style: TextStyle = .largeTitle) -> Font {
        .custom(weight.psName, size: size, relativeTo: style)
    }

    static func body(_ size: CGFloat, _ weight: SansWeight = .regular,
                     relativeTo style: TextStyle = .body) -> Font {
        .custom(weight.psName, size: size, relativeTo: style)
    }

    enum DisplayWeight {
        case medium, semibold, bold
        var psName: String {
            switch self {
            case .medium:   return "FunnelDisplay-Medium"
            case .semibold: return "FunnelDisplay-SemiBold"
            case .bold:     return "FunnelDisplay-Bold"
            }
        }
    }

    enum SansWeight {
        case regular, medium, semibold, bold
        var psName: String {
            switch self {
            case .regular:  return "FunnelSans-Regular"
            case .medium:   return "FunnelSans-Medium"
            case .semibold: return "FunnelSans-SemiBold"
            case .bold:     return "FunnelSans-Bold"
            }
        }
    }
}
