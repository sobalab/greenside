import SwiftUI

/// Book wizard **Step 2 of 3** — confirm/edit the golfer's details for the
/// booking. Pushed onto `BookRootView`'s navigation stack; reads and mutates the
/// shared `BookingViewModel` at `appState.booking`.
struct ConfirmProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    var body: some View {
        @Bindable var booking = appState.booking

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                header

                if booking.profile != nil {
                    identityHeader(booking: booking)
                    detailsForm(booking: booking)
                    recap(booking: booking)
                } else {
                    loading
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xxl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .background(Theme.Palette.background)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Your details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomBar(booking: booking) }
        .task { await booking.loadProfileIfNeeded() }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                appeared = true
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: booking.profile == nil)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            EyebrowText("Step 2 of 3")
            Text("Your details")
                .font(Theme.Typography.display(40, .bold))
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("Confirm who is playing.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loading

    private var loading: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Theme.Palette.primary)
            Text("Loading your profile…")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxxl)
    }

    // MARK: - Identity header

    /// A clean identity block echoing who the round is being booked for —
    /// avatar, full name and a verified seal on a white surface.
    private func identityHeader(booking: BookingViewModel) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            AvatarView(
                name: booking.profile?.fullName ?? "",
                imageName: booking.profile?.avatarImageName,
                size: 56
            )
            VStack(alignment: .leading, spacing: 3) {
                EyebrowText("Booking for")
                Text(booking.profile?.fullName ?? "")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.Palette.accent)
        }
        .gsCard()
    }

    // MARK: - Form

    private func detailsForm(booking: BookingViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            fieldGroup(title: "Golfer") {
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    GSFormField(
                        label: "First name",
                        placeholder: "First",
                        text: bind(booking, \.firstName)
                    )
                    GSFormField(
                        label: "Last name",
                        placeholder: "Last",
                        text: bind(booking, \.lastName)
                    )
                }

                fieldDivider

                GSFormField(
                    label: "Handicap index",
                    placeholder: "Optional",
                    text: handicapBinding(booking),
                    keyboard: .decimalPad,
                    footnote: "Leave blank if you don't have one yet."
                )
            }

            fieldGroup(title: "Contact") {
                GSFormField(
                    label: "Email",
                    placeholder: "you@email.com",
                    text: bind(booking, \.email),
                    keyboard: .emailAddress,
                    autocapitalization: .never,
                    contentType: .emailAddress
                )

                fieldDivider

                GSFormField(
                    label: "Phone",
                    placeholder: "(555) 555-5555",
                    text: bind(booking, \.phone),
                    keyboard: .phonePad,
                    contentType: .telephoneNumber
                )
            }
        }
    }

    /// A titled cluster of fields grouped onto a single white card surface.
    private func fieldGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            EyebrowText(title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gsCard(padding: Theme.Spacing.lg)
    }

    private var fieldDivider: some View {
        Divider().overlay(Theme.Palette.hairline)
    }

    // MARK: - Recap

    @ViewBuilder
    private func recap(booking: BookingViewModel) -> some View {
        if let course = booking.course {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                EyebrowText("Your round")
                Text(course.name)
                    .font(Theme.Typography.titleHero)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Divider().overlay(Theme.Palette.hairline)

                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    StatColumn(label: "Date", value: Self.dateFormatter.string(from: booking.date))
                    Spacer(minLength: 0)
                    StatColumn(
                        label: "Tee time",
                        value: booking.selectedTeeTime?.timeDisplay ?? "—",
                        alignment: .center
                    )
                    Spacer(minLength: 0)
                    StatColumn(
                        label: "Players",
                        value: "\(booking.players)",
                        alignment: .trailing
                    )
                    .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gsCard(padding: Theme.Spacing.lg)
        }
    }

    // MARK: - Bottom CTA

    private func bottomBar(booking: BookingViewModel) -> some View {
        VStack(spacing: 0) {
            Divider().overlay(Theme.Palette.hairline)
            Button("Continue to payment") {
                Haptics.tap()
                booking.goToReviewAndPay()
            }
            .buttonStyle(GSPrimaryButtonStyle(enabled: canContinue(booking)))
            .disabled(!canContinue(booking))
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xs)
        }
        .background(Theme.Palette.surface)
    }

    private func canContinue(_ booking: BookingViewModel) -> Bool {
        guard let profile = booking.profile else { return false }
        return !profile.firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !profile.lastName.trimmingCharacters(in: .whitespaces).isEmpty
            && !profile.email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Bindings

    /// A binding into a `String` member of the optional profile. Reads and
    /// writes through `booking.profile?.<keyPath>`; a nil profile reads "".
    private func bind(
        _ booking: BookingViewModel,
        _ keyPath: WritableKeyPath<UserProfile, String>
    ) -> Binding<String> {
        Binding(
            get: { booking.profile?[keyPath: keyPath] ?? "" },
            set: { booking.profile?[keyPath: keyPath] = $0 }
        )
    }

    /// Maps the optional `handicap: Double?` to/from an editable string.
    private func handicapBinding(_ booking: BookingViewModel) -> Binding<String> {
        Binding(
            get: {
                guard let value = booking.profile?.handicap else { return "" }
                return value.formatted(.number.precision(.fractionLength(0...1)))
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                booking.profile?.handicap = trimmed.isEmpty ? nil : Double(trimmed)
            }
        )
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()
}

// MARK: - Styled form field

/// An eyebrow label stacked over a `TextField` inside a subtly-tinted rounded
/// surface with a hairline border — the standard Greenside form input.
private struct GSFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var contentType: UITextContentType? = nil
    var footnote: String? = nil

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            EyebrowText(label)
            TextField(placeholder, text: $text)
                .font(Theme.Typography.bodyMedium)
                .foregroundStyle(Theme.Palette.ink)
                .tint(Theme.Palette.primary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .textContentType(contentType)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .background(
                    Theme.Palette.surfaceMuted,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .stroke(
                            focused ? Theme.Palette.primary : Theme.Palette.hairline,
                            lineWidth: focused ? 1.5 : 1
                        )
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: focused)
            if let footnote {
                Text(footnote)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Palette.inkTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        ConfirmProfileView()
    }
    .environment(AppState())
}
