import SwiftUI

/// A pushed detail screen for a single course. Shows a full-bleed hero image,
/// key stats, tags, an about section, facilities, and reviews, with a persistent
/// "Book this course" CTA pinned to the bottom safe area.
struct CourseDetailView: View {
    let course: Course

    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                hero
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    statsCard
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
                .frame(height: 300)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.55), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(course.name)
                    .font(Theme.Typography.titleHero)
                    .foregroundStyle(Theme.Palette.onDark)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 2)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .semibold))
                    Text(course.location)
                        .font(Theme.Typography.body)
                }
                .foregroundStyle(Theme.Palette.onDark.opacity(0.9))

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
                .padding(.top, 2)
            }
            .padding(Theme.screenPadding)
        }
        .frame(height: 300)
    }

    // MARK: - Stats

    private var statsCard: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            stat("Par", "\(course.par)")
            Spacer(minLength: 0)
            stat("Holes", "\(course.holes)")
            Spacer(minLength: 0)
            stat("Length", "\(course.lengthYards) yd")
            Spacer(minLength: 0)
            stat("Distance", String(format: "%.1f mi", course.distanceMiles))
        }
        .frame(maxWidth: .infinity)
        .gsCard(padding: Theme.Spacing.lg)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        StatColumn(label: label, value: value, alignment: .center)
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
            Text("About")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Palette.ink)
            Text(course.about)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let designer = course.designer {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.and.ruler.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Palette.accent)
                    Text("Designed by \(designer)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Facilities

    private var facilities: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Facilities")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Palette.ink)
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
                appState.booking.start(course: course)
                appState.selectedTab = .book
            } label: {
                Text("Book this course — from $\(course.greenFee)")
            }
            .buttonStyle(GSPrimaryButtonStyle())
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xs)
        }
        .background(Theme.Palette.surface)
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
