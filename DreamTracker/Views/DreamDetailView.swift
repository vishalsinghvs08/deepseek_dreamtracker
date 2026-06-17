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

    private var horizonColor: Color {
        planetaryColor(dream.horizon)
    }

    var body: some View {
        ZStack {
            // MARK: - Deep Space Gradient Background
            deepSpaceBackground
                .ignoresSafeArea()

            // MARK: - Subtle Animated Starfield
            starfieldCanvas
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // MARK: - Content
            ScrollView {
                VStack(spacing: 0) {
                    // Completion Toggle + Celebration
                    completionSection
                        .padding(.top, 32)
                        .padding(.bottom, 24)

                    // Title
                    titleSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    // Horizon Badge
                    horizonSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                    // Divider
                    glassDivider
                        .padding(.horizontal, 24)

                    // Notes
                    notesSection
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 32)

                    // Meta
                    metaSection
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
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
                    .foregroundColor(.white.opacity(0.8))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdits()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(horizonColor)
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Share button
                        Button {
                            shareDream()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color.white.opacity(0.60))
                        }

                        // More menu
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
                                .foregroundColor(Color.white.opacity(0.60))
                        }
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

    // MARK: - Deep Space Background

    private var deepSpaceBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.04, blue: 0.18),
                Color(red: 0.08, green: 0.04, blue: 0.22),
                Color(red: 0.03, green: 0.02, blue: 0.12),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Animated Starfield (10–15 slow stars)

    private var starfieldCanvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                // 12 subtle stars that slowly drift and twinkle
                for i in 0..<12 {
                    let seed = Double(i) * 0.618033988749895
                    let baseX = (sin(seed * 42.0) * 0.5 + 0.5)
                    let baseY = (cos(seed * 37.0) * 0.5 + 0.5)
                    let driftX = sin(t * 0.02 + seed * 10) * 0.012
                    let driftY = cos(t * 0.015 + seed * 8) * 0.012
                    let x = (baseX + driftX) * size.width
                    let y = (baseY + driftY) * size.height
                    let starSize: CGFloat = 1.0 + (sin(seed * 100) * 0.5 + 0.5) * 2.0
                    let twinkle = sin(t * 0.4 + seed * 15) * 0.5 + 0.5
                    let opacity = 0.12 + twinkle * 0.28
                    let rect = CGRect(x: x, y: y, width: starSize, height: starSize)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
        }
    }

    // MARK: - Glass Divider

    private var glassDivider: some View {
        RoundedRectangle(cornerRadius: 0.5)
            .fill(.white.opacity(0.15))
            .frame(height: 0.5)
    }

    // MARK: - Completion Section (DRAMATIC celebration)

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
                // DRAMATIC PhaseAnimator glow — larger (200pt), blurred
                if celebrationPhase > 0 {
                    Circle()
                        .fill(horizonColor.opacity(0.18))
                        .frame(width: 200, height: 200)
                        .scaleEffect(celebrationPhase == 1 ? 1.0 : 2.0)
                        .opacity(celebrationPhase == 2 ? 0 : 1)
                        .blur(radius: 12)

                    // Secondary outer glow ring
                    Circle()
                        .fill(horizonColor.opacity(0.08))
                        .frame(width: 260, height: 260)
                        .scaleEffect(celebrationPhase == 1 ? 1.0 : 1.6)
                        .opacity(celebrationPhase == 2 ? 0 : 1)
                        .blur(radius: 20)
                }

                // DRAMATIC Sparkle burst — 16 sparkles in 2 concentric rings
                if showSparkles {
                    // Inner ring: 8 sparkles
                    ForEach(0..<8) { i in
                        let angle = Double(i) * .pi * 2 / 8
                        let spread = celebrationPhase == 1 ? 1.0 : 2.2
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                            .foregroundColor(horizonColor)
                            .scaleEffect(showSparkles ? 1.3 : 0.2)
                            .offset(
                                x: cos(angle) * 55 * spread,
                                y: sin(angle) * 55 * spread
                            )
                            .opacity(celebrationPhase == 2 ? 0 : 1)
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.45),
                                value: showSparkles
                            )
                    }
                    // Outer ring: 8 more sparkles, offset angle, different icon
                    ForEach(0..<8) { i in
                        let angle = Double(i) * .pi * 2 / 8 + .pi / 8
                        let spread = celebrationPhase == 1 ? 1.0 : 2.4
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(horizonColor.opacity(0.65))
                            .scaleEffect(showSparkles ? 1.1 : 0.15)
                            .offset(
                                x: cos(angle) * 78 * spread,
                                y: sin(angle) * 78 * spread
                            )
                            .opacity(celebrationPhase == 2 ? 0 : 1)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.5).delay(0.06),
                                value: showSparkles
                            )
                    }
                }

                // Main toggle circle — planetaryColor when complete, glass when not
                ZStack {
                    Circle()
                        .fill(
                            currentDream.isCompleted
                                ? horizonColor
                                : Color.white.opacity(0.08)
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(
                                    currentDream.isCompleted
                                        ? horizonColor.opacity(0.5)
                                        : Color.white.opacity(0.12),
                                    lineWidth: 2
                                )
                        )
                        .shadow(
                            color: currentDream.isCompleted
                                ? horizonColor.opacity(0.4)
                                : .clear,
                            radius: 16, y: 4
                        )

                    Image(systemName: currentDream.isCompleted ? "checkmark" : "circle")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(currentDream.isCompleted ? .white : .white.opacity(0.5))
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

        // Phase 2: expand outward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                celebrationPhase = 2
            }
        }

        // Phase 3: fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                celebrationPhase = 0
                showSparkles = false
            }
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Title (New York serif, white, bold)

    private var titleSection: some View {
        Group {
            if isEditing {
                TextField("Your dream...", text: $editedTitle, axis: .vertical)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundColor(Color.white)
                    .lineLimit(2...4)
            } else {
                Text(currentDream.title)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundColor(Color.white)
                    .strikethrough(currentDream.isCompleted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .matchedGeometryEffect(id: "title-\(dream.id)", in: animationNamespace)
                    .onTapGesture { enterEditMode() }
            }
        }
    }

    // MARK: - Horizon Badge

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
                    .foregroundColor(horizonColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(horizonColor.opacity(0.15))
                    )
                }
                .disabled(!isEditing)
                .matchedGeometryEffect(id: "horizon-\(dream.id)", in: animationNamespace)
            }
        }
    }

    // MARK: - Notes (dark glass card, white text)

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.60))
                .textCase(.uppercase)

            if isEditing {
                TextEditor(text: $editedNotes)
                    .font(.body)
                    .foregroundColor(Color.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )
            } else {
                if currentDream.notes.isEmpty {
                    Text("Tap Edit to add notes about this dream...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.3))
                        .onTapGesture { enterEditMode() }
                } else {
                    Text(currentDream.notes)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(5)
                        .onTapGesture { enterEditMode() }
                }
            }
        }
        .padding(16)
        .cosmicSurface(level: .base, radius: 16)
    }

    // MARK: - Meta

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let done = currentDream.completedAt {
                Label(
                    "Achieved \(done.formatted(date: .long, time: .omitted))",
                    systemImage: "flag.checkered"
                )
                .font(.caption)
                .foregroundColor(horizonColor)
            } else {
                Label(
                    "Created \(currentDream.createdAt.formatted(date: .long, time: .omitted))",
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.60))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Edit Helpers (preserving all existing logic)

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

    // MARK: - Share (UIActivityViewController)

    private func shareDream() {
        let statusText = currentDream.isCompleted ? "✨ Achieved!" : "🌱 In progress"
        var shareText = "🌟 My Dream: \(currentDream.title)\n\n"
        shareText += "Horizon: \(currentDream.horizon.rawValue)\n"
        shareText += "Status: \(statusText)\n"
        if !currentDream.notes.isEmpty {
            shareText += "\nNotes: \(currentDream.notes)\n"
        }
        if let done = currentDream.completedAt {
            shareText += "\nAchieved on \(done.formatted(date: .long, time: .omitted))\n"
        }
        shareText += "\n— DreamTracker"

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}
