import SwiftUI

// MARK: - Reflection View

struct ReflectionView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var isWriting = false

    // MARK: Body

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Pinned header + manifesto ──
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text("Reflections")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    // Manifesto card (pinned, no blur)
                    manifestoCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }

                // ── Scrollable reflections ──
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Section label
                        if !viewModel.reflections.isEmpty {
                            Text("Past Entries")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "98989E"))
                                .tracking(2)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                        }

                        if viewModel.reflections.isEmpty {
                            emptyState
                        } else {
                            ForEach(viewModel.reflections) { reflection in
                                reflectionRow(reflection)
                            }
                        }
                    }
                    .padding(.bottom, 100) // space for FAB
                }
            }

            // ── Floating Action Button ──
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        openWriting()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(hex: "0A84FF"))
                            .clipShape(Circle())
                            .shadow(
                                color: Color(hex: "0A84FF").opacity(0.4),
                                radius: 16,
                                y: 8
                            )
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .fullScreenCover(isPresented: $isWriting) {
            WritingSheetView(
                onSave: { content, promptType in
                    saveEntry(content: content, promptType: promptType)
                },
                onCancel: {
                    isWriting = false
                }
            )
        }
    }

    // MARK: - Manifesto Card

    private var manifestoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "98989E"))
                .tracking(3)

            Text(viewModel.goal?.why ?? "Define your why — the deep reason that drives you forward every day.")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "141414"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No reflections yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "98989E"))
            Text("Tap + to begin writing")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "98989E").opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Reflection Row

    private func reflectionRow(_ reflection: Reflection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date
            Text(reflection.createdAt, style: .date)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "98989E"))

            // Content — no boxes, no borders, just clean text
            Text(reflection.content)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Actions

    private func openWriting() {
        isWriting = true
    }

    private func saveEntry(content: String, promptType: PromptType) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let finalContent: String
        if promptType == .monthlyCheckin {
            finalContent = "\(PromptType.monthlyCheckin.prompt)\n\n\(trimmed)"
        } else {
            finalContent = trimmed
        }

        viewModel.saveReflection(content: finalContent, promptType: promptType)
        isWriting = false
    }
}

// MARK: - Writing Sheet View

struct WritingSheetView: View {
    let onSave: (String, PromptType) -> Void
    let onCancel: () -> Void

    @State private var entryText = ""
    @State private var selectedPromptType: PromptType = .freeform
    @State private var showPromptPicker = false
    @FocusState private var isFocused: Bool

    private let springAnimation: Animation = .spring(response: 0.55, dampingFraction: 0.825)

    var body: some View {
        ZStack {
            Color(hex: "0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Custom header ──
                HStack {
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "98989E"))

                    Spacer()

                    // Prompt toggle
                    Button {
                        withAnimation(springAnimation) {
                            showPromptPicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 11, weight: .medium))
                            Text(selectedPromptType == .monthlyCheckin ? "Monthly" : "Freeform")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "98989E"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color(hex: "141414"))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Button("Save") {
                        onSave(entryText, selectedPromptType)
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(
                        entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color(hex: "98989E").opacity(0.5)
                            : Color(hex: "0A84FF")
                    )
                    .disabled(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // ── Prompt picker (expandable) ──
                if showPromptPicker {
                    promptTypeSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()
                    .background(Color.white.opacity(0.06))

                // ── Text editor ──
                TextEditor(text: $entryText)
                    .focused($isFocused)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .tint(Color(hex: "0A84FF"))
            }
        }
        .onAppear {
            isFocused = true
        }
    }

    // MARK: - Prompt Type Selector

    private var promptTypeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHOOSE PROMPT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(hex: "98989E").opacity(0.6))
                .tracking(2)

            HStack(spacing: 8) {
                promptChip(
                    type: .freeform,
                    label: "Freeform",
                    icon: "pencil",
                    isSelected: selectedPromptType == .freeform
                )
                promptChip(
                    type: .monthlyCheckin,
                    label: "Monthly",
                    icon: "calendar",
                    isSelected: selectedPromptType == .monthlyCheckin
                )
            }

            // Show prompt hint when monthly is selected
            if selectedPromptType == .monthlyCheckin {
                Text(PromptType.monthlyCheckin.prompt)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(Color(hex: "98989E").opacity(0.7))
                    .lineSpacing(5)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 4)
    }

    private func promptChip(
        type: PromptType,
        label: String,
        icon: String,
        isSelected: Bool
    ) -> some View {
        Button {
            withAnimation(springAnimation) {
                selectedPromptType = type
                if type == .freeform {
                    showPromptPicker = false
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "98989E"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color(hex: "0A84FF") : Color(hex: "141414")
            )
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ReflectionView()
            .environmentObject(AppViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
