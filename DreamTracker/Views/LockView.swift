import SwiftUI

struct LockView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                        .frame(width: 120, height: 120)

                    Image(systemName: "sparkles")
                        .font(.system(size: 42, weight: .thin))
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(.bottom, 36)

                // Title
                VStack(spacing: 6) {
                    Text("DreamTracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("What do you want your life to look like?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 48)

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }

                // Unlock button
                Button {
                    Task { await viewModel.unlockApp() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.system(size: 18, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                        Text("Unlock")
                            .font(.headline)
                    }
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.blue)
                    )
                }
                .accessibilityLabel("Unlock with Face ID")
                .accessibilityHint("Authenticate to access your dreams")
                .padding(.horizontal, 40)
                .padding(.bottom, 48)

                Spacer()
            }
        }
    }
}
