import SwiftUI

// MARK: - SmartSearchPill

/// The app's soul: a frosted, floating pill showing the current query, with a
/// dark circular `sparkles` button. Tapping it presents filters.
struct SmartSearchPill: View {
    let query: String
    var onTap: () -> Void = {}
    var onSparkles: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.Palette.muted)
            Text(query)
                .font(.body(15, .medium))
                .foregroundStyle(Theme.Palette.charcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 8)
            Button {
                Haptics.tap()
                onSparkles()
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Palette.volt)
                    .frame(width: 40, height: 40)
                    .background(Theme.Palette.charcoal, in: Circle())
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.leading, 20)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.45), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 22, y: 10)
        .contentShape(Capsule())
        .onTapGesture {
            Haptics.tap()
            onTap()
        }
    }
}

// MARK: - MetricBlock

/// Oversized number in Funnel Display, a tiny unit beside it, and a rounded-top
/// capsule accent bar beneath (volt for the primary value, muted otherwise).
struct MetricBlock: View {
    let value: String
    let unit: String
    var tone: Tone = .volt
    var size: CGFloat = 28

    enum Tone { case volt, muted }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.display(size, .bold))
                    .foregroundStyle(Theme.Palette.charcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.body(12, .medium))
                    .foregroundStyle(Theme.Palette.muted)
                    .lineLimit(1)
                    .fixedSize()
            }
            UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5, style: .continuous)
                .fill(tone == .volt ? Theme.Palette.volt : Theme.Palette.muted.opacity(0.35))
                .frame(height: 6)
        }
    }
}

// MARK: - TeeSlotRow

/// A full-bleed row for one available tee time — big time on the left, price +
/// spots on the right. Prime/limited slots wear the living dawn gradient.
struct TeeSlotRow: View {
    let time: String
    let meridiem: String
    let price: Int
    let spotsLeft: Int
    var isPrime: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(time)
                        .font(.display(34, .bold))
                        .foregroundStyle(Theme.Palette.charcoal)
                    Text(meridiem)
                        .font(.body(15, .medium))
                        .foregroundStyle(isPrime ? Theme.Palette.charcoal.opacity(0.7) : Theme.Palette.muted)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(price)")
                        .font(.display(22, .semibold))
                        .foregroundStyle(Theme.Palette.charcoal)
                    Text(spotsLeft > 0 ? "\(spotsLeft) left" : "full")
                        .font(.body(12, .medium))
                        .foregroundStyle(isPrime ? Theme.Palette.charcoal.opacity(0.65) : Theme.Palette.muted)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background {
                if isPrime {
                    DawnGradient()
                } else {
                    Theme.Palette.paper
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(PressScaleStyle(scale: 0.985))
    }
}

// MARK: - FeaturedCourseCard

/// The Discover drama moment — an editorial featured course over the ContourHero
/// texture, with metric blocks and the single volt "Book" pill.
struct FeaturedCourseCard: View {
    let course: Course
    var onOpen: () -> Void = {}
    var onBook: () -> Void = {}

    private var nextTee: TeeTime? {
        SampleData.availability(for: course, on: Date())
            .flatMap(\.teeTimes)
            .first { !$0.isSoldOut }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.Palette.paper, Theme.Palette.mist],
                           startPoint: .top, endPoint: .bottom)
            ContourHero(tint: Theme.Palette.clay, seed: birdieSeed(course.name), maxOpacity: 0.7)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text("Featured near you")
                        .font(.body(12, .semibold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Palette.muted)
                    Spacer()
                    CircleIconButton(systemName: "arrow.up.right", size: 44, style: .ink, action: onOpen)
                }

                Text(course.name)
                    .font(.display(40, .bold))
                    .foregroundStyle(Theme.Palette.charcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)

                HStack(spacing: 8) {
                    Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(Theme.Palette.charcoal)
                    Text(course.ratingDisplay).font(.body(14, .semibold)).foregroundStyle(Theme.Palette.charcoal)
                    Text("· \(String(format: "%.1f", course.distanceMiles)) mi · Par \(course.par)")
                        .font(.body(14, .regular))
                        .foregroundStyle(Theme.Palette.muted)
                }
                .padding(.top, 8)

                HStack(spacing: 22) {
                    MetricBlock(value: "$\(course.greenFee)", unit: "per player", tone: .volt, size: 26)
                        .fixedSize()
                    if let nextTee {
                        MetricBlock(value: shortTime(nextTee), unit: "next tee", tone: .muted, size: 26)
                            .fixedSize()
                    }
                    Spacer(minLength: 0)
                }
                .padding(.top, 26)

                if let nextTee {
                    PillButton(title: "Book the \(shortTime(nextTee)) tee time", style: .volt, fill: true, action: onBook)
                        .padding(.top, 18)
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 26, y: 14)
    }

    private func shortTime(_ tee: TeeTime) -> String {
        String(tee.timeDisplay.prefix(while: { $0 != " " }))
    }
}

// MARK: - DiscoverCourseCard

/// A nearby course row — name, rating, distance, next available time, green fee.
struct DiscoverCourseCard: View {
    let course: Course
    var onTap: () -> Void = {}

    private var nextTee: TeeTime? {
        SampleData.availability(for: course, on: Date())
            .flatMap(\.teeTimes)
            .first { !$0.isSoldOut }
    }

    var body: some View {
        Button {
            Haptics.tap()
            onTap()
        } label: {
            HStack(spacing: 16) {
                CourseImage(course: course)
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(course.name)
                        .font(.display(19, .semibold))
                        .foregroundStyle(Theme.Palette.charcoal)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill").font(.system(size: 11)).foregroundStyle(Theme.Palette.charcoal)
                        Text(course.ratingDisplay).font(.body(13, .semibold)).foregroundStyle(Theme.Palette.charcoal)
                        Text("· \(String(format: "%.1f", course.distanceMiles)) mi")
                            .font(.body(13, .regular)).foregroundStyle(Theme.Palette.muted)
                    }
                    if let nextTee {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("Next").font(.body(12, .medium)).foregroundStyle(Theme.Palette.muted)
                            Text(nextTee.timeDisplay).font(.body(12, .semibold)).foregroundStyle(Theme.Palette.charcoal)
                            Text("· from $\(course.greenFee)").font(.body(12, .medium)).foregroundStyle(Theme.Palette.muted)
                        }
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Palette.charcoal)
                    .frame(width: 38, height: 38)
                    .background(Theme.Palette.mist, in: Circle())
            }
            .padding(14)
            .background(Theme.Palette.paper, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Theme.Palette.charcoal.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
        }
        .buttonStyle(PressScaleStyle(scale: 0.98))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 18) {
            SmartSearchPill(query: "Sat · 2 players · morning · under $60")
            FeaturedCourseCard(course: SampleData.pebbleBeach)
            TeeSlotRow(time: "10:24", meridiem: "AM", price: 54, spotsLeft: 2, isPrime: true)
            TeeSlotRow(time: "11:40", meridiem: "AM", price: 48, spotsLeft: 4)
            DiscoverCourseCard(course: SampleData.bethpageBlack)
        }
        .padding()
    }
    .background(Theme.Palette.ground)
}
