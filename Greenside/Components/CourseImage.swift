import SwiftUI
import UIKit

/// Displays a course's photo when the named asset exists, and otherwise a
/// deterministic branded gradient stand-in. The app doesn't ship course
/// bitmaps yet, so this keeps every card and hero looking intentional; drop
/// real images named `course.imageName` into the asset catalog and they light
/// up automatically.
struct CourseImage: View {
    let course: Course

    var body: some View {
        if let image = UIImage(named: course.imageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            CourseImagePlaceholder(seed: course.name)
        }
    }
}

/// The gradient fairway stand-in used when a course image asset is missing.
/// Palette is chosen deterministically from the seed so a given course always
/// looks the same.
struct CourseImagePlaceholder: View {
    let seed: String

    private static let palettes: [[Color]] = [
        [Color(hex: 0x2F5A38), Color(hex: 0x6FA24C)],
        [Color(hex: 0x1F4A38), Color(hex: 0x3F7D5A)],
        [Color(hex: 0x3B5A2B), Color(hex: 0x86A957)],
        [Color(hex: 0x24503A), Color(hex: 0x5E9E7A)],
        [Color(hex: 0x2C5140), Color(hex: 0x7FB26A)],
    ]

    var body: some View {
        let palette = Self.palettes[Self.stableHash(seed) % Self.palettes.count]
        ZStack {
            LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
            TopographicLines(color: .white, opacity: 0.10)
            Image(systemName: "flag.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    /// A process-stable hash (Swift's `hashValue` is randomized per launch).
    private static func stableHash(_ string: String) -> Int {
        var hash = 5381
        for byte in string.utf8 { hash = (hash &* 33) &+ Int(byte) }
        return abs(hash)
    }
}

#Preview {
    VStack {
        CourseImagePlaceholder(seed: "Pebble Beach")
        CourseImagePlaceholder(seed: "Augusta National")
    }
    .frame(height: 400)
}
