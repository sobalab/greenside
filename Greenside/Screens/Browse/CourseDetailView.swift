import SwiftUI

/// A pushed detail screen for a single course, in the Birdie design language.
/// Full-width clipped hero image, an oversized course name, hero metric blocks,
/// tags, about, facilities, and reviews — with a frosted volt "Book" CTA pinned
/// to the bottom safe area. Navigation, data, and interactions are preserved.
struct CourseDetailView: View {
    let course: Course

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                hero
                title
                metrics
                if !course.tags.isEmpty { tags }
                about
                if !course.facilities.isEmpty { facilities }
                if !course.reviews.isEmpty { reviews }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left", style: .frosted) {
                dismiss()
            }
            Spacer()
            CircleIconButton(
                systemName: isSaved ? "heart.fill" : "heart",
                style: isSaved ? .volt : .frosted
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isSaved.toggle()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Hero

    private var hero: some View {
        CourseImage(course: course)
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
    }

    // MARK: - Title

    private var title: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(course.name)
                .font(.display(40, .bold))
                .foregroundStyle(Theme.Palette.charcoal)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Palette.charcoal)
                Text(course.ratingDisplay)
                    .font(.body(15, .semibold))
                    .foregroundStyle(Theme.Palette.charcoal)
                Text("· \(course.reviewCount) reviews · \(String(format: "%.1f", course.distanceMiles)) mi · Par \(course.par)")
                    .font(.body(15, .regular))
                    .foregroundStyle(Theme.Palette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    // MARK: - Metrics

    private var metrics: some View {
        HStack(alignment: .top, spacing: 26) {
            MetricBlock(value: "\(course.par)", unit: "par", tone: .volt, size: 24)
                .fixedSize()
            MetricBlock(value: "\(course.lengthYards)", unit: "yards", tone: .muted, size: 24)
                .fixedSize()
            MetricBlock(value: "\(course.holes)", unit: "holes", tone: .muted, size: 24)
                .fixedSize()
            MetricBlock(value: course.ratingDisplay, unit: "rating", tone: .muted, size: 24)
                .fixedSize()
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Tags

    private var tags: some View {
        CourseDetailFlowLayout(spacing: 8) {
            ForEach(course.tags) { tag in
                Text(tag.rawValue)
                    .font(.body(13, .medium))
                    .foregroundStyle(Theme.Palette.charcoal)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.Palette.paper, in: Capsule())
                    .overlay(Capsule().stroke(Theme.Palette.mist, lineWidth: 1))
            }
        }
    }

    // MARK: - About

    private var about: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.display(22, .bold))
                .foregroundStyle(Theme.Palette.charcoal)
            Text(course.about)
                .font(.body(16, .regular))
                .foregroundStyle(Theme.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            if let designer = course.designer {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Palette.muted)
                    Text("Designed by \(designer)")
                        .font(.body(14, .medium))
                        .foregroundStyle(Theme.Palette.muted)
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Facilities

    private var facilities: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Facilities")
                .font(.display(22, .bold))
                .foregroundStyle(Theme.Palette.charcoal)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 12
            ) {
                ForEach(course.facilities) { facility in
                    CourseDetailFacilityTile(facility: facility)
                }
            }
        }
    }

    // MARK: - Reviews

    private var reviews: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Reviews")
                    .font(.display(22, .bold))
                    .foregroundStyle(Theme.Palette.charcoal)
                Text("\(course.reviewCount)")
                    .font(.body(15, .medium))
                    .foregroundStyle(Theme.Palette.muted)
            }
            ForEach(course.reviews) { review in
                CourseDetailReviewCard(review: review)
            }
        }
    }

    // MARK: - Bottom CTA

    private var bottomBar: some View {
        PillButton(
            title: "Book a tee time · from $\(course.greenFee)",
            style: .volt,
            fill: true
        ) {
            Haptics.impact()
            appState.booking.start(course: course)
            appState.selectedTab = .book
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Facility tile

private struct CourseDetailFacilityTile: View {
    let facility: Facility

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: facility.systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Palette.charcoal)
                .frame(width: 24)
            Text(facility.name)
                .font(.body(14, .medium))
                .foregroundStyle(Theme.Palette.charcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.Palette.mist,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}

// MARK: - Review card

private struct CourseDetailReviewCard: View {
    let review: Review

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AvatarView(name: review.authorName, size: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.authorName)
                        .font(.body(15, .semibold))
                        .foregroundStyle(Theme.Palette.charcoal)
                    CourseDetailStarRow(rating: review.rating)
                }
                Spacer(minLength: 8)
                Text(Self.dateFormatter.string(from: review.date))
                    .font(.body(13, .medium))
                    .foregroundStyle(Theme.Palette.muted)
            }
            Text(review.text)
                .font(.body(15, .regular))
                .foregroundStyle(Theme.Palette.charcoal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.Palette.charcoal.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
    }
}

// MARK: - Star row

private struct CourseDetailStarRow: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundStyle(index < rating ? Theme.Palette.star : Theme.Palette.muted.opacity(0.4))
            }
        }
    }
}

// MARK: - Flow layout

/// A simple wrapping layout so course tags flow onto multiple lines when they
/// exceed the available width.
private struct CourseDetailFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: maxWidth == .infinity ? rows.map(\.width).max() ?? 0 : maxWidth,
                      height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = subviews[item].sizeThatFits(.unspecified)
                subviews[item].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var items: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !current.items.isEmpty && x + size.width > maxWidth {
                rows.append(current)
                current = Row()
                x = 0
            }
            current.items.append(index)
            x += size.width + spacing
            current.width = min(maxWidth, x - spacing)
            current.height = max(current.height, size.height)
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: SampleData.pebbleBeach)
    }
    .environment(AppState())
}
