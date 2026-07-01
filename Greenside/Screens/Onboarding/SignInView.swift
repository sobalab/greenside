import SwiftUI

/// The auth gate. Presented in the `.signIn` onboarding phase. Signing in (or
/// continuing with Apple) advances the app into the main experience; the back
/// control returns to the welcome screen. All actions are demo-friendly and never
/// gate on real credentials. Restyled into the Birdie design language.
struct SignInView: View {
    @Environment(AppState.self) private var appState

    @State private var email = "joe.bradley@example.com"
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                VStack(spacing: 16) {
                    SignInField(
                        eyebrow: "Email",
                        placeholder: "you@example.com",
                        text: $email,
                        isSecure: false
                    )
                    SignInField(
                        eyebrow: "Password",
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: true
                    )
                }

                VStack(spacing: 14) {
                    PillButton(title: "Sign in", style: .volt, fill: true) {
                        signIn()
                    }

                    Button {
                        Haptics.tap()
                    } label: {
                        Text("Forgot password?")
                            .font(.body(14, .medium))
                            .foregroundStyle(Theme.Palette.muted)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PressScaleStyle())
                }

                orDivider

                PillButton(title: "Continue with Apple", icon: "apple.logo", style: .ink, fill: true) {
                    signIn()
                }

                footer
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 44)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Palette.ground.ignoresSafeArea())
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 22) {
            CircleIconButton(systemName: "chevron.left", style: .frosted) {
                appState.phase = .welcome
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Welcome back")
                    .font(.display(40, .bold))
                    .foregroundStyle(Theme.Palette.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Sign in to pick up where you left off.")
                    .font(.body(16, .regular))
                    .foregroundStyle(Theme.Palette.muted)
            }
        }
    }

    private var orDivider: some View {
        HStack(spacing: 14) {
            line
            Text("or")
                .font(.body(13, .medium))
                .foregroundStyle(Theme.Palette.muted)
            line
        }
    }

    private var line: some View {
        RoundedRectangle(cornerRadius: 1, style: .continuous)
            .fill(Theme.Palette.charcoal.opacity(0.08))
            .frame(height: 1)
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Text("New to Greenside?")
                .font(.body(14, .regular))
                .foregroundStyle(Theme.Palette.muted)
            Button {
                signIn()
            } label: {
                Text("Create account")
                    .font(.body(14, .semibold))
                    .foregroundStyle(Theme.Palette.charcoal)
            }
            .buttonStyle(PressScaleStyle())
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func signIn() {
        appState.phase = .main
    }
}

// MARK: - Field

/// A labelled input row: a small uppercase eyebrow above a rounded paper surface
/// hosting the field. Switches between a plain `TextField` and a `SecureField`
/// based on `isSecure`; the email variant configures itself for email entry.
private struct SignInField: View {
    let eyebrow: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(.body(12, .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Palette.muted)

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
            .font(.body(16, .regular))
            .foregroundStyle(Theme.Palette.charcoal)
            .tint(Theme.Palette.volt)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.Palette.paper)
                    .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
            )
        }
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
