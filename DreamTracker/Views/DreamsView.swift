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
    @FocusState private var isFocused: Bool

    private let maxFreePerHorizon = 3

    @Namespace private var animationNamespace

    private let horizons = TimeHorizon.allCases

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
                // Gradient underlay — like iOS Weather
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.06),
                        Color(.systemGroupedBackground),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    progressHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    horizonPicker
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    Divider()
                    if filteredDreams.isEmpty {
                        emptyState
                    } else {
                        dreamList
                    }
                }
            }
            .navigationTitle("Dreams")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) { settingsSheet }
            .sheet(isPresented: $showAddSheet) { addDreamSheet }
            .sheet(isPresented: $showProUpgrade) { proUpgradeSheet }
            .overlay(alignment: .bottomTrailing) {
                addButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        HStack(spacing: 12) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: totalDreams > 0 ? CGFloat(totalCompleted) / CGFloat(totalDreams) : 0)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: totalCompleted)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(totalCompleted) of \(totalDreams) dreams achieved")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Horizon Pills

    private var horizonPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(horizons) { horizon in
                    let count = viewModel.dreams.filter { $0.horizon == horizon }.count
                    let done = viewModel.dreams.filter { $0.horizon == horizon && $0.isCompleted }.count
                    let isActive = activeHorizon == horizon

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            activeHorizon = horizon
                        }
                    } label: {
                        HStack(spacing: 6) {
                            // Mini dot indicator
                            Circle()
                                .fill(dotColor(total: count, done: done, isActive: isActive))
                                .frame(width: 6, height: 6)

                            Text(horizon.shortLabel)
                                .font(.system(size: 14, weight: isActive ? .semibold : .regular))

                            if count > 0 {
                                Text("\(done)/\(count)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(isActive ? .white.opacity(0.7) : .secondary)
                            }
                        }
                        .foregroundColor(isActive ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isActive ? Color.blue : Color(.systemGray6))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isActive ? Color.clear : Color(.systemGray4), lineWidth: 0.5)
                        )
                    }
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0.92)
                            .opacity(phase.isIdentity ? 1 : 0.7)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func dotColor(total: Int, done: Int, isActive: Bool) -> Color {
        if total == 0 { return isActive ? .white.opacity(0.4) : .gray.opacity(0.3) }
        if done == total { return .green }
        return isActive ? .white : .blue
    }

    // MARK: - Dream List

    private var dreamList: some View {
        List {
            Section {
                ForEach(filteredDreams) { dream in
                    NavigationLink {
                        DreamDetailView(dream: dream, animationNamespace: animationNamespace)
                    } label: {
                        DreamRow(dream: dream) {
                            viewModel.toggleDream(id: dream.id)
                        }
                        .matchedGeometryEffect(id: "row-\(dream.id)", in: animationNamespace)
                    }
                    .contextMenu {
                        contextMenu(for: dream)
                    } preview: {
                        DreamDetailPreview(dream: dream)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteDream(id: dream.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            viewModel.toggleDream(id: dream.id)
                        } label: {
                            Label(
                                dream.isCompleted ? "Undo" : "Complete",
                                systemImage: dream.isCompleted ? "arrow.uturn.backward" : "checkmark"
                            )
                        }
                        .tint(dream.isCompleted ? .orange : .green)
                    }
                }
                .onMove { source, dest in
                    viewModel.moveDream(from: source, to: dest, horizon: activeHorizon)
                }
            } header: {
                HStack {
                    Text("\(filteredDreams.count) dream\(filteredDreams.count == 1 ? "" : "s")")
                    Spacer()
                    if completedCount > 0 {
                        Text("\(completedCount) done")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(filteredDreams.count > 1 ? .active : .inactive))
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
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.blue.opacity(0.4))
                .symbolEffect(.bounce, value: activeHorizon)
            Text("No dreams for \(activeHorizon.shortLabel)")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("What do you want to achieve\nin the next \(activeHorizon.rawValue.lowercased())?")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.6))
                .multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Label("Add Your First Dream", systemImage: "plus")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            showAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .light)
                )
                .overlay(
                    Circle()
                        .fill(Color.blue)
                        .opacity(0.85)
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
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
                                      ? Color.blue.opacity(0.3)
                                      : Color.blue)
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
                        .foregroundColor(viewModel.storeManager.isPro ? .blue : .secondary)
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
                                .foregroundColor(.blue)
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
                    .foregroundStyle(.blue)
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
                                .fill(Color.blue)
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
                .foregroundStyle(.blue)
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

// MARK: - Dream Row

private struct DreamRow: View {
    let dream: Dream
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dream.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(dream.isCompleted ? Color.green : Color.gray.opacity(0.4))
                .symbolRenderingMode(dream.isCompleted ? .hierarchical : .monochrome)
                .symbolEffect(.bounce, value: dream.isCompleted)

            VStack(alignment: .leading, spacing: 3) {
                Text(dream.title)
                    .font(.body)
                    .foregroundColor(dream.isCompleted ? .secondary : .primary)
                    .strikethrough(dream.isCompleted)
                    .lineLimit(2)

                if !dream.notes.isEmpty {
                    Text(dream.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if dream.isCompleted {
                Image(systemName: "flag.checkered")
                    .font(.caption2)
                    .foregroundColor(.green.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
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
