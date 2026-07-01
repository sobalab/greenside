import SwiftUI

/// Book wizard **step 3 of 3** — review the round, tune add-ons, see the full
/// price breakdown, and pay. Pushed content owned by `BookRootView`; all state
/// is read from the shared `appState.booking`, with pricing derived from its
/// `draft` booking.
struct ReviewAndPayView: View {
    @Environment(AppState.self) private var appState
    @State private var showPaymentSheet = false
    @State private var selectedCard = PaymentCard.options[0]

    var body: some View {
        @Bindable var booking = appState.booking

        ZStack {
            Theme.Palette.background.ignoresSafeArea()

            if let draft = booking.draft {
                content(booking: booking, draft: draft)
            } else {
                ProgressView()
                    .tint(Theme.Palette.primary)
            }
        }
        .navigationTitle("Review & pay")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let draft = booking.draft {
                payBar(booking: booking, draft: draft)
            }
        }
        .sheet(isPresented: $showPaymentSheet) {
            PaymentPickerSheet(selected: $selectedCard)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(booking: BookingViewModel, draft: Booking) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header

                SummaryCard(draft: draft)

                addOnsSection(booking: booking)

                priceBreakdown(draft: draft)

                paymentMethod
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.xs)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            EyebrowText("Step 3 of 3")
            Text("Review & pay")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Palette.ink)
        }
    }

    // MARK: - Add-ons

    private func addOnsSection(booking: BookingViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Enhance your round")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Palette.ink)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(booking.addOns) { addOn in
                    AddOnRow(
                        addOn: addOn,
                        isSelected: booking.isSelected(addOn),
                        action: { booking.toggleAddOn(addOn) }
                    )
                }
            }
        }
    }

    // MARK: - Price breakdown

    private func priceBreakdown(draft: Booking) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            PriceRow(
                label: "Green fees (\(draft.players) × $\(draft.teeTime.price))",
                value: "$\(draft.greenFeesTotal)"
            )
            if draft.addOnsTotal > 0 {
                PriceRow(label: "Add-ons", value: "$\(draft.addOnsTotal)")
            }
            PriceRow(label: "Service fee", value: "$\(draft.serviceFee)")
            PriceRow(label: "Taxes", value: "$\(draft.taxes)")

            Divider()
                .overlay(Theme.Palette.hairline)
                .padding(.vertical, Theme.Spacing.xxs)

            HStack(alignment: .firstTextBaseline) {
                Text("Total")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer(minLength: Theme.Spacing.sm)
                Text("$\(draft.total)")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Palette.primary)
                    .contentTransition(.numericText())
            }
        }
        .gsCard()
    }

    // MARK: - Payment method

    private var paymentMethod: some View {
        Button {
            Haptics.tap()
            showPaymentSheet = true
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: selectedCard.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Palette.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Theme.Palette.surfaceMuted,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedCard.displayName)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("Default payment method")
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }

                Spacer(minLength: Theme.Spacing.sm)

                Text("Change")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Palette.accent)
            }
            .gsCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pay bar

    private func payBar(booking: BookingViewModel, draft: Booking) -> some View {
        Button {
            Task {
                Haptics.impact()
                await booking.confirmAndPay()
                Haptics.success()
            }
        } label: {
            if booking.isProcessingPayment {
                ProgressView()
                    .tint(Theme.Palette.onDark)
            } else {
                Text("Pay $\(draft.total)")
                    .contentTransition(.numericText())
            }
        }
        .buttonStyle(GSGradientButtonStyle())
        .disabled(booking.isProcessingPayment)
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.xs)
        .background(Theme.Palette.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Palette.hairline)
                .frame(height: 1)
        }
    }
}

// MARK: - Summary card

private struct SummaryCard: View {
    let draft: Booking

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            CourseImage(course: draft.course)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(draft.course.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                Text("\(draft.dateDisplay) · \(draft.teeTime.timeDisplay)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                Text("\(draft.players) player\(draft.players == 1 ? "" : "s")")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }

            Spacer(minLength: 0)
        }
        .gsCard()
    }
}

// MARK: - Add-on row

private struct AddOnRow: View {
    let addOn: AddOn
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: addOn.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.Palette.primary : Theme.Palette.inkSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Theme.Palette.surfaceMuted,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(addOn.title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(addOn.subtitle)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }

                Spacer(minLength: Theme.Spacing.xs)

                Text("$\(addOn.price)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Palette.ink)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.Palette.primary : Theme.Palette.inkTertiary)
            }
            .padding(Theme.Spacing.md)
            .background(
                Theme.Palette.surface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(
                        isSelected ? Theme.Palette.primary : Theme.Palette.hairline,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Price row

private struct PriceRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Palette.inkSecondary)
            Spacer(minLength: Theme.Spacing.sm)
            Text(value)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Palette.ink)
        }
    }
}

// MARK: - Payment method picker

private struct PaymentCard: Identifiable, Hashable {
    let id = UUID()
    let brand: String
    let last4: String
    let systemImage: String

    var displayName: String {
        last4.isEmpty ? brand : "\(brand) ending \(last4)"
    }

    static let options: [PaymentCard] = [
        PaymentCard(brand: "Visa", last4: "4242", systemImage: "creditcard.fill"),
        PaymentCard(brand: "Mastercard", last4: "8319", systemImage: "creditcard.fill"),
        PaymentCard(brand: "Apple Pay", last4: "", systemImage: "applelogo"),
    ]
}

private struct PaymentPickerSheet: View {
    @Binding var selected: PaymentCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(PaymentCard.options) { card in
                        Button {
                            Haptics.selection()
                            selected = card
                            dismiss()
                        } label: {
                            HStack(spacing: Theme.Spacing.md) {
                                Image(systemName: card.systemImage)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Theme.Palette.primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Theme.Palette.surfaceMuted,
                                        in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                    )
                                Text(card.displayName)
                                    .font(Theme.Typography.headline)
                                    .foregroundStyle(Theme.Palette.ink)
                                Spacer(minLength: Theme.Spacing.sm)
                                Image(systemName: selected == card ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(selected == card ? Theme.Palette.primary : Theme.Palette.inkTertiary)
                            }
                            .gsCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.screenPadding)
            }
            .background(Theme.Palette.background)
            .navigationTitle("Payment method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let appState = AppState()
    appState.booking.course = SampleData.pebbleBeach
    let slots = SampleData.availability(for: SampleData.pebbleBeach, on: Date())
    appState.booking.selectedTeeTime = slots.flatMap(\.teeTimes).first { !$0.isSoldOut }
    appState.booking.players = 2
    appState.booking.selectedAddOnIDs = [AddOn.defaults[0].id]

    return NavigationStack {
        ReviewAndPayView()
    }
    .environment(appState)
}
