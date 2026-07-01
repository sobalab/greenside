import SwiftUI
import UIKit

/// Circular avatar. Uses the named image asset if present, otherwise falls back
/// to the user's initials on the brand green — so it looks right before any
/// avatar bitmaps are added.
struct AvatarView: View {
    let name: String
    var imageName: String? = nil
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let imageName, let image = UIImage(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Theme.Palette.primary
                    Text(initials)
                        .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.Palette.onDark)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

#Preview {
    HStack {
        AvatarView(name: "Joe Bradley", size: 64)
        AvatarView(name: "Dana West", imageName: "missing", size: 44)
    }
    .padding()
}
