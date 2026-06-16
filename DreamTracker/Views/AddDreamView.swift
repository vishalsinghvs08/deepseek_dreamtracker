import SwiftUI

struct AddDreamView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var lucidityScore = 3
    @State private var isLucid = false
    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var isSaving = false
    @State private var titleError = false

    // Suggested tags for quick add
    let suggestedTags = ["flying", "water", "chase", "falling", "people", "travel", "night", "animals"]

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.10)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Title field
                        FieldSection(label: "DREAM TITLE") {
                            TextField("e.g. Flying over the ocean...", text: $title)
                                .foregroundColor(.white)
                                .font(.system(size: 16, design: .rounded))
                                .tint(.purple)
                                .onChange(of: title) { _ in
                                    if titleError && !title.isEmpty { titleError = false }
                                }
                        }
                        if titleError {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.8))
                                    .font(.caption)
                                Text("A title is required")
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.8))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, -12)
                        }

                        // Content field
                        FieldSection(label: "DREAM DESCRIPTION") {
                            ZStack(alignment: .topLeading) {
                                if content.isEmpty {
                                    Text("Describe your dream in detail...")
                                        .foregroundColor(.white.opacity(0.3))
                                        .font(.system(size: 15, design: .rounded))
                                        .padding(.top, 1)
                                }
                                TextEditor(text: $content)
                                    .foregroundColor(.white)
                                    .font(.system(size: 15, design: .rounded))
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .tint(.purple)
                            }
                        }

                        // Lucidity slider
                        FieldSection(label: "LUCIDITY SCORE") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Clarity level")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                    Spacer()
                                    Text("\(lucidityScore) / 5")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(lucidityColor)
                                }
                                HStack(spacing: 10) {
                                    ForEach(1...5, id: \.self) { score in
                                        Button {
                                            withAnimation(.spring(response: 0.25)) {
                                                lucidityScore = score
                                            }
                                        } label: {
                                            VStack(spacing: 4) {
                                                Circle()
                                                    .fill(score <= lucidityScore ? lucidityColor : Color.white.opacity(0.1))
                                                    .frame(width: 36, height: 36)
                                                    .overlay(
                                                        Text("\(score)")
                                                            .font(.system(size: 14, weight: .semibold))
                                                            .foregroundColor(score <= lucidityScore ? .white : .white.opacity(0.3))
                                                    )
                                                    .scaleEffect(score == lucidityScore ? 1.1 : 1.0)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Lucid toggle
                        FieldSection(label: "TYPE") {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Lucid Dream")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("I was aware I was dreaming")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                Spacer()
                                Toggle("", isOn: $isLucid)
                                    .tint(Color(red: 0.5, green: 0.3, blue: 0.9))
                            }
                        }

                        // Tags
                        FieldSection(label: "TAGS") {
                            VStack(alignment: .leading, spacing: 12) {
                                // Tag input
                                HStack {
                                    TextField("Add a tag...", text: $tagInput)
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                        .tint(.purple)
                                        .onSubmit { addTag() }
                                    if !tagInput.isEmpty {
                                        Button(action: addTag) {
                                            Image(systemName: "return")
                                                .foregroundColor(.purple)
                                                .font(.system(size: 14))
                                        }
                                    }
                                }

                                // Suggested tags
                                let availableSuggestions = suggestedTags.filter { !tags.contains($0) }
                                if !availableSuggestions.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(availableSuggestions, id: \.self) { suggestion in
                                                Button {
                                                    withAnimation { tags.append(suggestion) }
                                                } label: {
                                                    Text("+ \(suggestion)")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.5))
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 5)
                                                        .background(Color.white.opacity(0.07))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                }

                                // Added tags
                                if !tags.isEmpty {
                                    FlowLayout(tags: tags)
                                    // Remove option
                                    Button {
                                        withAnimation { tags.removeAll() }
                                    } label: {
                                        Text("Clear all tags")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                            }
                        }

                        // Save button
                        Button {
                            saveDream()
                        } label: {
                            HStack(spacing: 10) {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(isSaving ? "Saving..." : "Save Dream")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.5, green: 0.3, blue: 0.9), Color(red: 0.3, green: 0.4, blue: 0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)
                            .opacity(isSaving ? 0.7 : 1.0)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("New Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.04, green: 0.04, blue: 0.10), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    private var lucidityColor: Color {
        switch lucidityScore {
        case 5: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case 4: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case 3: return Color(red: 0.2, green: 0.6, blue: 0.7)
        case 2: return Color(red: 0.6, green: 0.5, blue: 0.3)
        default: return Color(red: 0.5, green: 0.3, blue: 0.4)
        }
    }

    private func addTag() {
        let sanitized = tagInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        guard !sanitized.isEmpty, !tags.contains(sanitized), sanitized.count <= 20 else {
            tagInput = ""
            return
        }
        withAnimation { tags.append(sanitized) }
        tagInput = ""
    }

    private func saveDream() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { titleError = true }
            return
        }
        isSaving = true
        let safeTitle = title.trimmingCharacters(in: .whitespaces)
        let safeContent = content.trimmingCharacters(in: .whitespaces)
        Task {
            await viewModel.addDream(
                title: safeTitle,
                content: safeContent,
                lucidityScore: lucidityScore,
                isLucid: isLucid,
                tags: tags
            )
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

struct FieldSection<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1.5)
            content
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
