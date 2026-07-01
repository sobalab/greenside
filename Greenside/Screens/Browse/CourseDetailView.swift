import SwiftUI

/// A pushed detail screen for a single course. Shows a full-bleed green hero,
/// an oversized course name, a hero metric row, tags, an about section,
/// facilities, and reviews, with a persistent gradient "Book a tee time" CTA
/// pinned to the bottom safe area.
struct CourseDetailView: View {
    let course: Course

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                    metricRow
                    if !course.tags.isEmpty { tags }
                    about
                    if !course.facilities.isEmpty { facilities }
                    if !course.reviews.isEmpty { reviews }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .background(Theme.Palette.background)
        .scrollIndicators(.hidden)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            CourseImage(course: course)
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.black.opacity(0.05), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12, weight: .semibold))
                    Text(course.location.uppercased())
                        .font(Theme.Typography.caption)
                        .tracking(0.8)
                }
                .foregroundStyle(Theme.Palette.onDark.opacity(0.85))

                Text(course.name)
                    .font(Theme.Typography.display(40, .bold))
                    .foregroundStyle(Theme.Palette.onDark)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 3)

                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Palette.star)
                    Text(course.ratingDisplay)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Palette.onDark)
                    Text("· \(course.reviewCount) reviews")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Palette.onDark.opacity(0.8))
                }
            }
            .padding(Theme.screenPadding)
            .padding(.bottom, Theme.Spacing.xs)
        }
        .frame(height: 380)
        .overlay(alignment: .top) { heroControls }
    }

    private var heroControls: some View {
        HStack {
            frostedButton(icon: "chevron.left") {
                Haptics.tap()
                dismiss()
            }
            Spacer(minLength: 0)
            frostedButton(icon: isSaved ? "heart.fill" : "heart", tint: isSaved ? Theme.Palette.lime : .white) {
                Haptics.tap()
                isSaved.toggle()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isSaved)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 54)
    }

    private func frostedButton(icon: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Hero metrics

    private var metricRow: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            metric(value: "\(course.par)", unit: "Par", accented: true)
            Spacer(minLength: 0)
            metric(value: "\(course.lengthYards)", unit: "Yards")
            Spacer(minLength: 0)
            metric(value: "\(course.holes)", unit: "Holes")
            Spacer(minLength: 0)
            metric(value: String(format: "%.1f", course.rating), unit: "Rating")
        }
        .frame(maxWidth: .infinity)
        .gsCard(padding: Theme.Spacing.lg)
    }

    private func metric(value: String, unit: String, accented: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Theme.Typography.display(26, .bold))
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            Capsule()
                .fill(accented ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.clear))
                .frame(width: 24, height: 3)
            Text(unit)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tags

    private var tags: some View {
        CourseDetailFlowLayout(spacing: Theme.Spacing.xs) {
            ForEach(course.tags) { tag in
                GSTag(title: tag.rawValue)
            }
        }
    }

    // MARK: - About

    private var about: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            EyebrowText("About the course")
            Text(course.about)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
            if let designer = course.designer {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.and.ruler.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Palette.accent)
                    Text("Designed by \(designer)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                .padding(.top, Theme.Spacing.xxs)
            }
        }
    }

    // MARK: - Facilities

    private var facilities: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            EyebrowText("Facilities")
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.sm),
                    GridItem(.flexible(), spacing: Theme.Spacing.sm),
                ],
                spacing: Theme.Spacing.sm
            ) {
                ForEach(course.facilities) { facility in
                    CourseDetailFacilityTile(facility: facility)
                }
            }
        }
    }

    // MARK: - Reviews

    private var reviews: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Reviews", actionTitle: "\(course.reviewCount)")
            ForEach(course.reviews) { review in
                CourseDetailReviewCard(review: review)
            }
        }
    }

    // MARK: - Bottom CTA

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Palette.hairline)
                .frame(height: 1)
            Button {
                Haptics.impact()
                appState.booking.start(course: course)
                appState.selectedTab = .book
            } label: {
                Text("Book a tee time · from $\(course.greenFee)")
                    .contentTransition(.numericText())
            }
            .buttonStyle(GSPrimaryButtonStyle())
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xs)
        }
        .background(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.05), radius: 12, y: -4)
    }
}

// MARK: - Facility tile

private struct CourseDetailFacilityTile: View {
    let facility: Facility

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: facility.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.primary)
                .frame(width: 24)
            Text(facility.name)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.Palette.surfaceMuted,
            in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                AvatarView(name: review.authorName, size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(review.authorName)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Palette.ink)
                    StarRow(rating: review.rating)
                }
                Spacer(minLength: Theme.Spacing.xs)
                Text(Self.dateFormatter.string(from: review.date))
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
            Text(review.text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gsCard()
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
