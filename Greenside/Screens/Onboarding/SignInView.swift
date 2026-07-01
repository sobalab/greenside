import SwiftUI

/// The auth gate. Presented in the `.signIn` onboarding phase. Signing in (or
/// continuing with Apple) advances the app into the main experience; the back
/// control returns to the welcome screen. All actions are demo-friendly and never
/// gate on real credentials.
struct SignInView: View {
    @Environment(AppState.self) private var appState

    @State private var email = "joe.bradley@example.com"
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header

                VStack(spacing: Theme.Spacing.md) {
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

                VStack(spacing: Theme.Spacing.md) {
                    Button("Sign in") { signIn() }
                        .buttonStyle(GSPrimaryButtonStyle())

                    Button("Forgot password?") { }
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Palette.accent)
                        .frame(maxWidth: .infinity)
                }

                orDivider

                Button(action: signIn) {
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
                .buttonStyle(.plain)

                footer
                    .padding(.top, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, Theme.Spacing.xs)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Palette.background.ignoresSafeArea())
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Button {
                appState.phase = .welcome
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(width: 44, height: 44)
                    .background(Theme.Palette.surfaceMuted, in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Welcome back")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Sign in to pick up where you left off.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Palette.inkSecondary)
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
            Button("Create account") { signIn() }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Palette.accent)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func signIn() {
        appState.phase = .main
    }
}

// MARK: - Field

/// A labelled input row: an eyebrow above a rounded white surface hosting the
/// field. Switches between a plain `TextField` and a `SecureField` based on
/// `isSecure`; the email variant configures itself for email entry.
private struct SignInField: View {
    let eyebrow: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool

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
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md - 2)
            .background(
                Theme.Palette.surface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(Theme.Palette.hairline, lineWidth: 1)
            )
        }
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
