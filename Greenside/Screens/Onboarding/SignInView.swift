import SwiftUI

/// The auth gate. Presented in the `.signIn` onboarding phase. Signing in (or
/// continuing with Apple) advances the app into the main experience; the back
/// control returns to the welcome screen. All actions are demo-friendly and never
/// gate on real credentials.
struct SignInView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var email = "joe.bradley@example.com"
    @State private var password = ""

    @FocusState private var focusedField: Field?
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header
                    .modifier(Entrance(index: 0, appeared: appeared, reduceMotion: reduceMotion))

                VStack(spacing: Theme.Spacing.md) {
                    SignInField(
                        eyebrow: "Email",
                        placeholder: "you@example.com",
                        text: $email,
                        isSecure: false,
                        field: .email,
                        focus: $focusedField
                    )
                    SignInField(
                        eyebrow: "Password",
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: true,
                        field: .password,
                        focus: $focusedField
                    )
                }
                .modifier(Entrance(index: 1, appeared: appeared, reduceMotion: reduceMotion))

                VStack(spacing: Theme.Spacing.md) {
                    Button("Sign in") {
                        Haptics.impact()
                        signIn()
                    }
                    .buttonStyle(GSPrimaryButtonStyle())

                    Button("Forgot password?") { }
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .frame(maxWidth: .infinity)
                }
                .modifier(Entrance(index: 2, appeared: appeared, reduceMotion: reduceMotion))

                orDivider
                    .modifier(Entrance(index: 3, appeared: appeared, reduceMotion: reduceMotion))

                Button {
                    Haptics.tap()
                    signIn()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 17, weight: .medium))
                        Text("Continue with Apple")
                            .font(Theme.Typography.button)
                    }
                    .foregroundStyle(Theme.Palette.onDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        Theme.Palette.ink,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    )
                }
                .buttonStyle(PressScaleStyle())
                .modifier(Entrance(index: 4, appeared: appeared, reduceMotion: reduceMotion))

                footer
                    .padding(.top, Theme.Spacing.xs)
                    .modifier(Entrance(index: 5, appeared: appeared, reduceMotion: reduceMotion))
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.xs)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Palette.background.ignoresSafeArea())
        .onAppear { appeared = true }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            Button {
                Haptics.tap()
                appState.phase = .welcome
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(width: 44, height: 44)
                    .background(Theme.Palette.surfaceMuted, in: Circle())
            }
            .buttonStyle(PressScaleStyle())

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Welcome back")
                    .font(Theme.Typography.display(44, .bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Sign in to pick up where you left off.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var orDivider: some View {
        HStack(spacing: Theme.Spacing.md) {
            line
            Text("or")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Palette.inkTertiary)
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(Theme.Palette.hairline)
            .frame(height: 1)
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("New to Greenside?")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Palette.inkSecondary)
            Button("Create account") {
                Haptics.tap()
                signIn()
            }
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Palette.accent)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func signIn() {
        appState.phase = .main
    }

    // MARK: - Focus

    /// The two focusable inputs on this screen.
    fileprivate enum Field: Hashable {
        case email, password
    }
}

// MARK: - Staggered entrance

/// A graceful, springy entrance for a block: it fades in and slides up with a
/// small per-block delay so the screen assembles top-to-bottom. Respects Reduce
/// Motion by dropping the vertical offset.
private struct Entrance: ViewModifier {
    let index: Int
    let appeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (appeared ? 0 : 16))
            .animation(
                .spring(response: 0.6, dampingFraction: 0.85)
                    .delay(Double(index) * 0.07),
                value: appeared
            )
    }
}

// MARK: - Field

/// A labelled input row: an eyebrow above a rounded white surface hosting the
/// field. Switches between a plain `TextField` and a `SecureField` based on
/// `isSecure`; the email variant configures itself for email entry. When focused,
/// the border springs to the brand green to signal the active field.
private struct SignInField: View {
    let eyebrow: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let field: SignInView.Field
    @FocusState.Binding var focus: SignInView.Field?

    private var isFocused: Bool { focus == field }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            EyebrowText(eyebrow)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Palette.ink)
            .tint(Theme.Palette.primary)
            .focused($focus, equals: field)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md - 2)
            .background(
                Theme.Palette.surface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(
                        isFocused ? Theme.Palette.primary : Theme.Palette.hairline,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isFocused)
        }
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
