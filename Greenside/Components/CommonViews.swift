import SwiftUI

// MARK: - Eyebrow

/// Small uppercase, letter-spaced label used above titles and stats.
struct EyebrowText: View {
    let text: String
    var onDark: Bool = false

    init(_ text: String, onDark: Bool = false) {
        self.text = text
        self.onDark = onDark
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.Typography.caption)
            .tracking(0.8)
            .foregroundStyle(onDark ? Theme.Palette.onDarkSecondary : Theme.Palette.inkSecondary)
    }
}

// MARK: - Section header

/// A section title with an optional trailing action (e.g. "See all").
struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Palette.ink)
            Spacer(minLength: Theme.Spacing.sm)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Palette.accent)
            }
        }
    }
}

// MARK: - Rating

/// Inline "★ 4.9 · 6 slots" style rating label.
struct RatingLabel: View {
    let rating: Double
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Palette.star)
            Text(String(format: "%.1f", rating))
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Palette.ink)
            if let trailing {
                Text("· \(trailing)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
        }
    }
}

/// Five-star row for reviews (filled up to `rating`).
struct StarRow: View {
    let rating: Int
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(Theme.Palette.star)
            }
        }
    }
}

// MARK: - Chips & tags

/// A selectable pill chip (Browse filters). Highlights green when selected.
struct GSChip: View {
    let title: String
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.callout)
                .foregroundStyle(isSelected ? Theme.Palette.onDark : Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs + 2)
                .background(isSelected ? Theme.Palette.primary : Theme.Palette.surface, in: Capsule())
                .overlay(Capsule().stroke(Theme.Palette.hairline, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

/// A small static tag pill (course tags like "Links", "Championship").
struct GSTag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Palette.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.Palette.accent.opacity(0.10), in: Capsule())
    }
}

/// White price pill overlaid on course imagery, e.g. "$595".
struct PriceTag: View {
    let amount: Int

    var body: some View {
        Text("$\(amount)")
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Palette.ink)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .background(Theme.Palette.surface, in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}

// MARK: - Stepper

/// A "−  N  +" control. The caller owns the value and the bounds, so this
/// composes cleanly with `BookingViewModel`'s player rules.
struct GSStepper: View {
    let value: Int
    var canDecrement: Bool = true
    var canIncrement: Bool = true
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            button("minus", enabled: canDecrement, action: onDecrement)
            Text("\(value)")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Palette.ink)
                .frame(minWidth: 28)
                .contentTransition(.numericText())
            button("plus", enabled: canIncrement, action: onIncrement)
        }
    }

    private func button(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? Theme.Palette.primary : Theme.Palette.inkTertiary)
                .frame(width: 40, height: 40)
                .background(Theme.Palette.surfaceMuted, in: Circle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Quick action card

/// Icon + title + subtitle card used in the Home "quick actions" row.
struct QuickActionCard: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Palette.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Theme.Palette.surfaceMuted,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(subtitle)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gsCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat column

/// An eyebrow label stacked over a value — "DATE / Mar 16". Works on light or
/// dark (hero card) surfaces.
struct StatColumn: View {
    let label: String
    let value: String
    var onDark: Bool = false
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label.uppercased())
                .font(Theme.Typography.caption)
                .tracking(0.6)
                .foregroundStyle(onDark ? Theme.Palette.onDarkSecondary : Theme.Palette.inkSecondary)
            Text(value)
                .font(Theme.Typography.title2)
                .foregroundStyle(onDark ? Theme.Palette.onDark : Theme.Palette.ink)
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            EyebrowText("Monday · March 2")
            SectionHeader(title: "Recommended", actionTitle: "See all") {}
            RatingLabel(rating: 4.9, trailing: "6 slots")
            StarRow(rating: 4)
            HStack {
                GSChip(title: "Nearby", isSelected: true)
                GSChip(title: "Top rated")
                GSTag(title: "Links")
            }
            PriceTag(amount: 595)
            GSStepper(value: 2, onDecrement: {}, onIncrement: {})
            HStack {
                StatColumn(label: "Date", value: "Mar 16")
                StatColumn(label: "Players", value: "2")
            }
        }
        .padding()
    }
    .background(Theme.Palette.background)
}
