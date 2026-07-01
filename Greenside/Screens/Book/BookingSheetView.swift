import SwiftUI

/// The **Booking sheet** — the austere counterpoint. Presented over the Tee
/// sheet with medium/large detents: choose players, holes, walk vs cart, and
/// add-ons, then confirm with the one loud volt pill. Reads the shared booking.
struct BookingSheetView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var holes = 18

    var body: some View {
        @Bindable var booking = appState.booking

        Group {
            if let draft = booking.draft {
                content(booking: booking, draft: draft)
            } else {
                ProgressView().tint(Theme.Palette.charcoal)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.Palette.ground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(34)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(booking: BookingViewModel, draft: Booking) -> some View {
        VStack(spacing: 0) {
            handle

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    summary(draft: draft)
                    playersPicker(booking: booking)
                    holesPicker
                    ridePicker(booking: booking)
                    addOnsSection(booking: booking)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) { confirmBar(booking: booking, draft: draft) }
    }

    // MARK: - Handle

    private var handle: some View {
        ZStack {
            HStack(spacing: 5) {
                ForEach(0..<12, id: \.self) { _ in
                    Circle().fill(Theme.Palette.muted.opacity(0.5)).frame(width: 4, height: 4)
                }
            }
            HStack {
                Spacer()
                CircleIconButton(systemName: "xmark", size: 36, style: .paper) { dismiss() }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Summary

    private func summary(draft: Booking) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(draft.course.name)
                .font(.display(28, .bold))
                .foregroundStyle(Theme.Palette.charcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(draft.dateDisplay) · \(draft.teeTime.timeDisplay)")
                .font(.body(15, .medium))
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    // MARK: - Players

    private func playersPicker(booking: BookingViewModel) -> some View {
        let maxPlayers = min(4, booking.selectedTeeTime?.spotsLeft ?? 4)
        return pickerSection(title: "Players") {
            HStack(spacing: 12) {
                ForEach(1...4, id: \.self) { n in
                    let enabled = n <= maxPlayers
                    Button {
                        Haptics.selection()
                        booking.players = n
                    } label: {
                        Text("\(n)")
                            .font(.display(20, .bold))
                            .foregroundStyle(booking.players == n ? Theme.Palette.paper : (enabled ? Theme.Palette.charcoal : Theme.Palette.muted.opacity(0.5)))
                            .frame(width: 54, height: 54)
                            .background {
                                if booking.players == n {
                                    Circle().fill(Theme.Palette.charcoal)
                                } else {
                                    Circle().fill(Theme.Palette.mist)
                                }
                            }
                    }
                    .buttonStyle(PressScaleStyle())
                    .disabled(!enabled)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Holes

    private var holesPicker: some View {
        pickerSection(title: "Holes") {
            SegmentedPills(options: [(9, "9 holes"), (18, "18 holes")], selection: $holes)
        }
    }

    // MARK: - Ride

    private func ridePicker(booking: BookingViewModel) -> some View {
        let cart = booking.addOns.first { $0.title == "Cart rental" }
        let usesCart = cart.map { booking.isSelected($0) } ?? false
        return pickerSection(title: "Getting around") {
            HStack(spacing: 10) {
                rideOption(title: "Walk", icon: "figure.walk", selected: !usesCart) {
                    if let cart, booking.isSelected(cart) { booking.toggleAddOn(cart) }
                }
                rideOption(title: "Cart", icon: "car.fill", selected: usesCart) {
                    if let cart, !booking.isSelected(cart) { booking.toggleAddOn(cart) }
                }
            }
        }
    }

    private func rideOption(title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 15, weight: .medium))
                Text(title).font(.body(16, .semibold))
            }
            .foregroundStyle(selected ? Theme.Palette.paper : Theme.Palette.charcoal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.Palette.charcoal)
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.Palette.paper)
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.Palette.mist, lineWidth: 1))
                }
            }
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: - Add-ons

    private func addOnsSection(booking: BookingViewModel) -> some View {
        let extras = booking.addOns.filter { $0.title != "Cart rental" }
        return pickerSection(title: "Add-ons") {
            VStack(spacing: 10) {
                ForEach(extras) { addOn in
                    let on = booking.isSelected(addOn)
                    Button {
                        Haptics.selection()
                        booking.toggleAddOn(addOn)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: addOn.systemImage)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(on ? Theme.Palette.charcoal : Theme.Palette.muted)
                                .frame(width: 44, height: 44)
                                .background(Theme.Palette.mist, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(addOn.title).font(.body(16, .semibold)).foregroundStyle(Theme.Palette.charcoal)
                                Text(addOn.subtitle).font(.body(13, .regular)).foregroundStyle(Theme.Palette.muted)
                            }
                            Spacer(minLength: 8)
                            Text("$\(addOn.price)").font(.body(15, .semibold)).foregroundStyle(Theme.Palette.charcoal)
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(on ? Theme.Palette.charcoal : Theme.Palette.muted.opacity(0.6))
                        }
                        .padding(14)
                        .background(Theme.Palette.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(on ? Theme.Palette.charcoal.opacity(0.5) : Theme.Palette.mist, lineWidth: on ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.98))
                }
            }
        }
    }

    // MARK: - Confirm bar

    private func confirmBar(booking: BookingViewModel, draft: Booking) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.Palette.mist).frame(height: 1)
            Button {
                Task {
                    Haptics.impact()
                    await booking.confirmAndPay()
                    Haptics.success()
                    dismiss()
                }
            } label: {
                if booking.isProcessingPayment {
                    ProgressView().tint(Theme.Palette.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Confirm · $\(draft.total)")
                        .font(.body(17, .semibold))
                        .foregroundStyle(Theme.Palette.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .contentTransition(.numericText())
                }
            }
            .background(Theme.Palette.volt, in: Capsule())
            .buttonStyle(PressScaleStyle())
            .disabled(booking.isProcessingPayment)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .background(Theme.Palette.ground)
    }

    // MARK: - Helpers

    private func pickerSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.body(12, .semibold))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.muted)
            content()
        }
    }
}

/// A two-option segmented pill control (holes 9/18).
private struct SegmentedPills: View {
    let options: [(Int, String)]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.0) { value, label in
                let selected = selection == value
                Button {
                    Haptics.selection()
                    selection = value
                } label: {
                    Text(label)
                        .font(.body(16, .semibold))
                        .foregroundStyle(selected ? Theme.Palette.paper : Theme.Palette.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.Palette.charcoal)
                            } else {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Theme.Palette.paper)
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.Palette.mist, lineWidth: 1))
                            }
                        }
                }
                .buttonStyle(PressScaleStyle())
            }
        }
    }
}

#Preview {
    Text("sheet host")
        .sheet(isPresented: .constant(true)) {
            BookingSheetView().environment({
                let a = AppState()
                a.booking.course = SampleData.pebbleBeach
                a.booking.selectedTeeTime = SampleData.availability(for: SampleData.pebbleBeach, on: Date()).flatMap(\.teeTimes).first
                return a
            }())
        }
}
