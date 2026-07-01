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

    // Deep green bases so the valley→summit contour ramp reads on top.
    private static let palettes: [[Color]] = [
        [Color(hex: 0x1C3B2C), Color(hex: 0x2E5D3A)],
        [Color(hex: 0x18342A), Color(hex: 0x2A5540)],
        [Color(hex: 0x203A22), Color(hex: 0x37582F)],
        [Color(hex: 0x1B4034), Color(hex: 0x2C5A45)],
        [Color(hex: 0x22462F), Color(hex: 0x315C3A)],
    ]

    var body: some View {
        let hash = Self.stableHash(seed)
        let palette = Self.palettes[hash % Self.palettes.count]
        ZStack {
            LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
            // The full-colour animated topographic survey — golf-course contours.
            AnimatedTopographicField(seed: hash, config: .card)
            Image(systemName: "flag.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(0.28))
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
