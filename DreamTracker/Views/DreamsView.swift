import SwiftUI
import TipKit

// MARK: - Dreams View

struct DreamsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var activeHorizon: TimeHorizon = .oneYear
    @State private var showAddSheet = false
    @State private var newDreamText = ""
    @State private var showSettings = false
    @State private var showProUpgrade = false
    @State private var showConfetti = false
    @State private var draggingDream: Dream?
    @State private var dreamToDecompose: Dream?
    @FocusState private var isFocused: Bool

    private let maxFreePerHorizon = 3

    @Namespace private var animationNamespace

    private let horizons = TimeHorizon.allCases

    // Pre-generated star particles for cosmic background
    @State private var stars: [StarParticle] = (0..<200).map { _ in
        StarParticle(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 0.5...2.5),
            opacity: CGFloat.random(in: 0.15...0.7)
        )
    }

    private var filteredDreams: [Dream] {
        viewModel.dreams
            .filter { $0.horizon == activeHorizon }
            .sorted { $0.order < $1.order }
    }

    private var completedCount: Int {
        filteredDreams.filter(\.isCompleted).count
    }

    private var totalCompleted: Int {
        viewModel.dreams.filter(\.isCompleted).count
    }

    private var totalDreams: Int {
        viewModel.dreams.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicNebula()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    progressHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                    // OrbitDial replacing horizon pills — centered at top
                    OrbitDial(activeHorizon: $activeHorizon)
                        .padding(.bottom, 12)

                    if filteredDreams.isEmpty {
                        emptyState
                    } else {
                        dreamCanvas
                    }
                }

                // Confetti overlay
                if showConfetti {
                    ConfettiOverlay()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                // Floating add button — frosted glass
                addButton
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 20)
                    .padding(.bottom, 16)
            }
            .navigationTitle("Dream Canvas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showSettings) { settingsSheet }
            .sheet(isPresented: $showAddSheet) { addDreamSheet }
            .sheet(isPresented: $showProUpgrade) { proUpgradeSheet }
            .sheet(item: $dreamToDecompose) { dream in
                DecomposeView(parentDream: dream)
            }
        }
    }

    // MARK: - Cosmic Background

    private var cosmicBackground: some View {
        ZStack {
            // Deep cosmic gradient — navy → deep purple → black
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

            // Star particles
            Canvas { context, size in
                for star in stars {
                    let x = star.x * size.width
                    let y = star.y * size.height
                    let rect = CGRect(x: x, y: y, width: star.size, height: star.size)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(star.opacity))
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: activeHorizon)
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: totalDreams > 0 ? CGFloat(totalCompleted) / CGFloat(totalDreams) : 0)
                    .stroke(planetaryColor(activeHorizon), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: totalCompleted)
            }
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 42, height: 42)
            )

            VStack(alignment: .leading, spacing: 1) {
                Text("\(totalCompleted) of \(totalDreams) dreams achieved")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    // MARK: - Dream Canvas

    private var dreamCanvas: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Section header
                HStack {
                    Text("\(filteredDreams.count) dream\(filteredDreams.count == 1 ? "" : "s")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                    Spacer()
                    if completedCount > 0 {
                        Text("\(completedCount) ✦ done")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(planetaryColor(activeHorizon))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                // Glass cards
                ForEach(Array(filteredDreams.enumerated()), id: \.element.id) { index, dream in
                    NavigationLink {
                        DreamDetailView(dream: dream, animationNamespace: animationNamespace)
                    } label: {
                        dreamCard(dream, index: index)
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: "card-\(dream.id)", in: animationNamespace)
                    .contextMenu {
                        contextMenu(for: dream)
                    } preview: {
                        DreamDetailPreview(dream: dream)
                    }
                    .onDrag {
                        draggingDream = dream
                        return NSItemProvider(object: dream.id.uuidString as NSString)
                    }
                    .onDrop(
                        of: [.text],
                        delegate: DreamDropDelegate(
                            dream: dream,
                            dreams: filteredDreams,
                            activeHorizon: activeHorizon,
                            viewModel: viewModel
                        )
                    )
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            await refreshCanvas()
        }
        .scrollIndicators(.hidden)
    }

    // Individual dream card — glassmorphism
    private func dreamCard(_ dream: Dream, index: Int) -> some View {
        let color = planetaryColor(dream.horizon)
        let isEven = index % 2 == 0

        return HStack(spacing: 0) {
            // Left color accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, 12)

            // Card content
            HStack(spacing: 14) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(dream.isCompleted
                            ? Color.green.opacity(0.3)
                            : Color.white.opacity(0.1))
                        .frame(width: 38, height: 38)

                    if dream.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(color.opacity(0.8))
                    }
                }
                .symbolEffect(.bounce, value: dream.isCompleted)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(dream.title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(dream.isCompleted ? .white.opacity(0.5) : .white)
                        .strikethrough(dream.isCompleted)
                        .lineLimit(2)

                    if !dream.notes.isEmpty {
                        Text(dream.notes)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    // Horizon chip
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 5, height: 5)
                        Text(dream.horizon.shortLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )
                }

                Spacer()

                // Completion toggle button
                VStack(spacing: 6) {
                    if dream.isCompleted {
                        Image(systemName: "flag.checkered")
                            .font(.caption2)
                            .foregroundColor(.green.opacity(0.6))
                    }

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            viewModel.toggleDream(id: dream.id)
                        }
                    } label: {
                        Image(systemName: dream.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(dream.isCompleted ? .orange : color)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, 16)
        // Alternating offset for flowing feel
        .padding(.leading, isEven ? 0 : 8)
        .padding(.trailing, isEven ? 8 : 0)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        )
        // Completed golden shimmer overlay
        .overlay(
            Group {
                if dream.isCompleted {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.15),
                                    Color.orange.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        )
        .scaleEffect(draggingDream?.id == dream.id ? 1.03 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: draggingDream?.id)
    }

    private func refreshCanvas() async {
        showConfetti = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        withAnimation(.easeOut(duration: 0.5)) {
            showConfetti = false
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenu(for dream: Dream) -> some View {
        Button {
            viewModel.toggleDream(id: dream.id)
        } label: {
            Label(
                dream.isCompleted ? "Mark Incomplete" : "Mark Complete",
                systemImage: dream.isCompleted ? "circle" : "checkmark.circle"
            )
        }

        Menu("Move To…") {
            ForEach(TimeHorizon.allCases) { horizon in
                if horizon != dream.horizon {
                    Button {
                        viewModel.updateDream(
                            id: dream.id,
                            title: dream.title,
                            notes: dream.notes,
                            horizon: horizon
                        )
                    } label: {
                        Label(horizon.rawValue, systemImage: "arrow.right")
                    }
                }
            }
        }

        // Decompose option for 5Y/10Y dreams
        if dream.horizon == .fiveYears || dream.horizon == .tenYears {
            Button {
                dreamToDecompose = dream
            } label: {
                Label("Decompose", systemImage: "square.split.2x2")
            }
        }

        Divider()

        Button(role: .destructive) {
            viewModel.deleteDream(id: dream.id)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(planetaryColor(activeHorizon).opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: planetaryIcon(activeHorizon))
                    .font(.system(size: 42, weight: .thin))
                    .foregroundColor(planetaryColor(activeHorizon).opacity(0.6))
                    .symbolEffect(.bounce, value: activeHorizon)
            }
            Text("No dreams for \(activeHorizon.shortLabel)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text("What do you want to achieve\nin the next \(activeHorizon.rawValue.lowercased())?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Label("Plant a Dream", systemImage: "plus.circle.fill")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(planetaryColor(activeHorizon))
                    )
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Add Button (FAB — frosted glass)

    private var addButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        }
    }

    // MARK: - Add Dream Sheet

    private var addDreamSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("What do you want to achieve\nin the next \(activeHorizon.rawValue.lowercased())?")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                TextField("Your dream…", text: $newDreamText, axis: .vertical)
                    .font(.body)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .lineLimit(3...6)
                    .padding(.horizontal)

                Button {
                    saveDream()
                } label: {
                    Text("Save Dream")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(newDreamText.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? planetaryColor(activeHorizon).opacity(0.3)
                                      : planetaryColor(activeHorizon))
                        )
                }
                .disabled(newDreamText.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSheet = false }
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveDream() {
        let text = newDreamText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        // Pro-gating: free tier limited to 3 dreams per horizon
        if !viewModel.storeManager.isPro {
            let count = viewModel.dreams.filter { $0.horizon == activeHorizon }.count
            if count >= maxFreePerHorizon {
                showAddSheet = false
                newDreamText = ""
                showProUpgrade = true
                return
            }
        }

        let order = viewModel.dreams.filter { $0.horizon == activeHorizon }.count
        let dream = Dream(title: text, horizon: activeHorizon, order: order)
        viewModel.dreams.append(dream)
        newDreamText = ""
        showAddSheet = false
        Task { try? await viewModel.store.saveDream(dream) }
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                // Pro status
                Section {
                    HStack {
                        Label(
                            viewModel.storeManager.isPro ? "DreamTracker Pro" : "DreamTracker Free",
                            systemImage: viewModel.storeManager.isPro ? "star.fill" : "star"
                        )
                        .foregroundColor(viewModel.storeManager.isPro ? planetaryColor(activeHorizon) : .secondary)
                        Spacer()
                        if viewModel.storeManager.isPro {
                            Text("Active")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }

                    if !viewModel.storeManager.isPro {
                        Button {
                            showSettings = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showProUpgrade = true
                            }
                        } label: {
                            Label("Get Pro — \(viewModel.storeManager.formattedPrice)", systemImage: "lock.open")
                                .foregroundColor(planetaryColor(activeHorizon))
                        }
                    }
                }

                // Data
                Section("Data") {
                    Button {
                        exportDreams()
                    } label: {
                        Label("Export Dreams", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        Task { await viewModel.deleteAllData() }
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0").foregroundColor(.secondary)
                    }

                    Button {
                        rateApp()
                    } label: {
                        Label("Rate DreamTracker", systemImage: "heart")
                    }

                    Button {
                        openPrivacyPolicy()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Pro Upgrade Sheet

    private var proUpgradeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(planetaryColor(activeHorizon))
                    .symbolRenderingMode(.hierarchical)

                Text("DreamTracker Pro")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    proFeature(icon: "infinity", text: "Unlimited dreams across all time horizons")
                    proFeature(icon: "icloud", text: "iCloud sync — your dreams on every device")
                    proFeature(icon: "square.grid.2x2", text: "Home screen widgets")
                    proFeature(icon: "lock.shield", text: "Face ID / Touch ID protection")
                    proFeature(icon: "heart", text: "Support independent development")
                }
                .padding(.horizontal, 20)

                Spacer()

                // Price
                VStack(spacing: 12) {
                    Button {
                        Task { await viewModel.storeManager.purchase() }
                    } label: {
                        HStack {
                            if viewModel.storeManager.purchaseInProgress {
                                ProgressView().tint(.white)
                            }
                            Text("Get Pro — \(viewModel.storeManager.formattedPrice)")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(planetaryColor(activeHorizon))
                        )
                    }
                    .disabled(viewModel.storeManager.purchaseInProgress)

                    Button("Restore Purchases") {
                        Task { await viewModel.storeManager.restorePurchases() }
                    }
                    .font(.subheadline)
                    .disabled(viewModel.storeManager.purchaseInProgress)

                    Text("One-time purchase. No subscription. Forever.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showProUpgrade = false }
                }
            }
            .alert("Purchase Error", isPresented: .constant(viewModel.storeManager.purchaseError != nil)) {
                Button("OK") { viewModel.storeManager.purchaseError = nil }
            } message: {
                Text(viewModel.storeManager.purchaseError ?? "")
            }
        }
    }

    private func proFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(planetaryColor(activeHorizon))
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }

    // MARK: - Actions

    private func exportDreams() {
        let text = viewModel.dreams
            .sorted { $0.horizon.rawValue < $1.horizon.rawValue }
            .map { "[\($0.isCompleted ? "✓" : " ")] [\($0.horizon.shortLabel)] \($0.title)" }
            .joined(separator: "\n")
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }

    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://dreamtracker.app/privacy") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Star Particle (for cosmic background)

private struct StarParticle {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: CGFloat
}

// MARK: - Dream Drop Delegate

private struct DreamDropDelegate: DropDelegate {
    let dream: Dream
    let dreams: [Dream]
    let activeHorizon: TimeHorizon
    let viewModel: AppViewModel

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let from = dreams.firstIndex(where: { $0.id != dream.id }),
              let toIndex = dreams.firstIndex(where: { $0.id == dream.id }),
              from != toIndex else { return }

        viewModel.moveDream(from: IndexSet(integer: from), to: toIndex, horizon: activeHorizon)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Confetti Overlay

private struct ConfettiOverlay: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let x = particle.x * size.width
                    let y = particle.y * size.height
                    let rect = CGRect(x: x, y: y, width: 8, height: 8)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color.opacity(particle.opacity))
                    )
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        let colors: [Color] = [.orange, .green, .blue, .purple, .indigo, .pink, .yellow, .mint]
        particles = (0..<60).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: -0.2...0),
                color: colors.randomElement()!,
                opacity: CGFloat.random(in: 0.5...1.0),
                speed: CGFloat.random(in: 0.3...0.7),
                wobble: CGFloat.random(in: -0.02...0.02)
            )
        }

        withAnimation(.linear(duration: 2.0)) {
            for i in particles.indices {
                particles[i].y += 1.2
                particles[i].x += particles[i].wobble
                particles[i].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            particles = []
        }
    }
}

private struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    let color: Color
    var opacity: CGFloat
    let speed: CGFloat
    let wobble: CGFloat
}

// MARK: - Detail Preview (for context menu)

private struct DreamDetailPreview: View {
    let dream: Dream

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: dream.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(dream.isCompleted ? .green : .secondary)
                Text(dream.title)
                    .font(.headline)
                    .lineLimit(2)
            }

            Label(dream.horizon.rawValue, systemImage: "clock")
                .font(.caption)
                .foregroundColor(.blue)

            if !dream.notes.isEmpty {
                Text(dream.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }
        }
        .padding()
        .frame(width: 280)
        .background(Color(.systemBackground))
    }
}
