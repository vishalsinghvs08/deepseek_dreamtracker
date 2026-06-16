import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showDeleteConfirm = false
    @State private var showPrivacyPolicy = false
    @State private var isDeleting = false

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.10).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Settings")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Account & Privacy")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Security section
                    SettingsSection(title: "SECURITY") {
                        SettingsRow(icon: "faceid", iconColor: Color(red: 0.3, green: 0.6, blue: 0.9), title: "Face ID / Touch ID", subtitle: "Required to unlock journal")
                        Divider().background(Color.white.opacity(0.08))
                        SettingsRow(icon: "key.fill", iconColor: Color(red: 0.5, green: 0.3, blue: 0.9), title: "Apple Keychain", subtitle: "Auth tokens stored securely")
                        Divider().background(Color.white.opacity(0.08))
                        SettingsRow(icon: "lock.shield.fill", iconColor: Color(red: 0.2, green: 0.6, blue: 0.4), title: "Encrypted Storage", subtitle: "All data encrypted at rest")
                        Divider().background(Color.white.opacity(0.08))
                        SettingsRow(icon: "network.badge.shield.half.filled", iconColor: Color(red: 0.6, green: 0.4, blue: 0.2), title: "SSL Pinning", subtitle: "Certificate-pinned HTTPS only")
                    }

                    // Account section
                    SettingsSection(title: "ACCOUNT") {
                        SettingsRow(icon: "person.crop.circle.fill", iconColor: Color(red: 0.4, green: 0.4, blue: 0.8), title: "Sign in with Apple", subtitle: "Primary authentication method")
                        Divider().background(Color.white.opacity(0.08))
                        SettingsRow(icon: "icloud.fill", iconColor: Color(red: 0.2, green: 0.5, blue: 0.8), title: "Cloud Sync", subtitle: "Dreams synced securely")
                    }

                    // Privacy section
                    SettingsSection(title: "PRIVACY") {
                        Button {
                            showPrivacyPolicy = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.3, green: 0.5, blue: 0.4))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Privacy Policy")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("View our data handling policy")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(14)
                        }
                    }

                    // Danger zone
                    SettingsSection(title: "DANGER ZONE") {
                        Button {
                            viewModel.lockApp()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                Text("Lock App Now")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(14)
                        }

                        Divider().background(Color.white.opacity(0.08))

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.8))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Delete Account")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.red.opacity(0.9))
                                    Text("Permanently wipes all data & account")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red.opacity(0.3))
                            }
                            .padding(14)
                        }
                    }

                    // App info
                    VStack(spacing: 4) {
                        Text("DreamTracker v1.0")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.2))
                        Text("All data protected by iOS Keychain & AES-256 Encryption")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.15))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 30)
                }
            }
        }
        // Delete Account Confirmation
        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All Data & Account", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your dreams and account data. This action cannot be undone.")
        }
        // Privacy Policy sheet
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1.5)
                .padding(.horizontal, 20)
            VStack(spacing: 0) {
                content
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.4))
        }
        .padding(14)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.10).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Privacy Policy")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Last updated: June 2025")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))

                        PolicySection(title: "Data We Collect", bodyText: "DreamTracker collects the dream entries you create, including titles, descriptions, dates, mood ratings, and tags. We do not collect personally identifiable information beyond your Apple ID for authentication.")

                        PolicySection(title: "How We Store Your Data", bodyText: "Authentication tokens are stored exclusively in the Apple Keychain. Dream data is encrypted using AES-256 at rest. Network communication uses HTTPS with TLS 1.3 and certificate pinning.")

                        PolicySection(title: "Third-Party Services", bodyText: "We use Apple Authentication (Sign in with Apple) for account management. We do not share your data with advertising networks or analytics providers.")

                        PolicySection(title: "Your Rights", bodyText: "You have the right to access, export, and permanently delete all your data at any time using the 'Delete Account' option in Settings. Account deletion triggers immediate wiping of all local and cloud-stored data.")

                        PolicySection(title: "Contact", bodyText: "For privacy inquiries, please contact us through the App Store support channel.")
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.04, green: 0.04, blue: 0.10), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

struct PolicySection: View {
    let title: String
    let bodyText: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(bodyText)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(5)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
