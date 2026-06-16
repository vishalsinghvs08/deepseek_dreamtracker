import SwiftUI

// MARK: - Dream Detail View

struct DreamDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    let dream: Dream
    var animationNamespace: Namespace.ID

    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""
    @State private var editedHorizon: TimeHorizon = .oneYear
    @State private var isEditing = false
    @State private var showDeleteConfirm = false
    @State private var showHorizonPicker = false

    // Celebration state
    @State private var celebrationPhase = 0
    @State private var showSparkles = false

    private var currentDream: Dream {
        viewModel.dreams.first(where: { $0.id == dream.id }) ?? dream
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Completion Toggle + Status
                completionSection
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                // MARK: Title
                titleSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // MARK: Horizon Badge
                horizonSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                Divider()
                    .padding(.horizontal, 20)

                // MARK: Notes
                notesSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                // MARK: Meta
                metaSection
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditing ? "Editing" : "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetEdits()
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdits()
                    }
                    .fontWeight(.semibold)
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { enterEditMode() } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Delete Dream", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                viewModel.deleteDream(id: dream.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(currentDream.title)\" will be permanently removed.")
        }
        .onAppear {
            editedTitle = currentDream.title
            editedNotes = currentDream.notes
            editedHorizon = currentDream.horizon
        }
    }

    // MARK: - Completion Section

    private var completionSection: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                viewModel.toggleDream(id: dream.id)
            }
            if !currentDream.isCompleted {
                triggerCelebration()
            }
        } label: {
            ZStack {
                // PhaseAnimator glow
                if celebrationPhase > 0 {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 100, height: 100)
                        .scaleEffect(celebrationPhase == 1 ? 1.0 : 1.5)
                        .opacity(celebrationPhase == 2 ? 0 : 1)
                }

                // Sparkle burst
                if showSparkles {
                    ForEach(0..<6) { i in
                        let angle = Double(i) * .pi * 2 / 6
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                            .scaleEffect(showSparkles ? 1.2 : 0.5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showSparkles)
                            .offset(
                                x: cos(angle) * 40 * (celebrationPhase == 1 ? 1 : 1.8),
                                y: sin(angle) * 40 * (celebrationPhase == 1 ? 1 : 1.8)
                            )
                            .opacity(celebrationPhase == 2 ? 0 : 1)
                    }
                }

                // Main circle
                ZStack {
                    Circle()
                        .fill(currentDream.isCompleted ? Color.green : Color(.systemGray5))
                        .frame(width: 72, height: 72)

                    Image(systemName: currentDream.isCompleted ? "checkmark" : "circle")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(currentDream.isCompleted ? .white : .secondary)
                        .symbolEffect(.bounce, value: currentDream.isCompleted)
                }
                .matchedGeometryEffect(id: "status-\(dream.id)", in: animationNamespace)
            }
        }
        .buttonStyle(.plain)
    }

    private func triggerCelebration() {
        celebrationPhase = 1
        showSparkles = true

        // Phase 2: expand
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                celebrationPhase = 2
            }
        }

        // Phase 3: fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                celebrationPhase = 0
                showSparkles = false
            }
        }

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Title

    private var titleSection: some View {
        Group {
            if isEditing {
                TextField("Your dream...", text: $editedTitle, axis: .vertical)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2...4)
            } else {
                Text(currentDream.title)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundColor(.primary)
                    .strikethrough(currentDream.isCompleted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .matchedGeometryEffect(id: "title-\(dream.id)", in: animationNamespace)
                    .onTapGesture { enterEditMode() }
            }
        }
    }

    // MARK: - Horizon

    private var horizonSection: some View {
        Group {
            if isEditing && showHorizonPicker {
                Picker("Horizon", selection: $editedHorizon) {
                    ForEach(TimeHorizon.allCases) { h in
                        Text(h.rawValue).tag(h)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                Button {
                    if isEditing {
                        withAnimation { showHorizonPicker = true }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(currentDream.horizon.rawValue)
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))
                }
                .disabled(!isEditing)
                .matchedGeometryEffect(id: "horizon-\(dream.id)", in: animationNamespace)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if isEditing {
                TextEditor(text: $editedNotes)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            } else {
                if currentDream.notes.isEmpty {
                    Text("Tap Edit to add notes about this dream...")
                        .font(.body)
                        .foregroundColor(.secondary.opacity(0.5))
                        .onTapGesture { enterEditMode() }
                } else {
                    Text(currentDream.notes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(5)
                        .onTapGesture { enterEditMode() }
                }
            }
        }
    }

    // MARK: - Meta

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let done = currentDream.completedAt {
                Label("Achieved \(done.formatted(date: .long, time: .omitted))", systemImage: "flag.checkered")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("Created \(currentDream.createdAt.formatted(date: .long, time: .omitted))", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func enterEditMode() {
        editedTitle = currentDream.title
        editedNotes = currentDream.notes
        editedHorizon = currentDream.horizon
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isEditing = true
        }
    }

    private func resetEdits() {
        editedTitle = currentDream.title
        editedNotes = currentDream.notes
        editedHorizon = currentDream.horizon
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isEditing = false
            showHorizonPicker = false
        }
    }

    private func saveEdits() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.updateDream(
            id: dream.id,
            title: trimmed,
            notes: editedNotes.trimmingCharacters(in: .whitespaces),
            horizon: editedHorizon
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isEditing = false
            showHorizonPicker = false
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
