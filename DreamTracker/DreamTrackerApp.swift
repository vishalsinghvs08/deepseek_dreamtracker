import SwiftUI
import LocalAuthentication

@main
struct DreamTrackerApp: App {
    @StateObject private var appViewModel = AppViewModel()

    @State private var jailbreakDetected = false

    var body: some Scene {
        WindowGroup {
            if jailbreakDetected {
                jailbreakWarning
            } else {
                RootView()
                    .environmentObject(appViewModel)
                    .task {
                        jailbreakDetected = JailbreakDetector.isJailbroken
                    }
            }
        }
    }

    private var jailbreakWarning: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Security Warning")
                .font(.title2)
                .fontWeight(.bold)
            Text("This device appears to be jailbroken. For your security, DreamTracker cannot run on compromised devices.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        Group {
            if viewModel.isUnlocked {
                MainTabView()
                    .transition(.opacity)
            } else {
                LockView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isUnlocked)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DreamsView()
                .tabItem {
                    Label("Dreams", systemImage: selectedTab == 0 ? "sparkles" : "sparkles")
                }
                .tag(0)

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: selectedTab == 1 ? "calendar.circle.fill" : "calendar")
                }
                .tag(1)
        }
    }
}

// MARK: - App View Model

@MainActor
class AppViewModel: ObservableObject {
    @Published var isUnlocked = false
    @Published var errorMessage: String?

    // Store
    @Published var storeManager = StoreManager()

    // Data
    @Published var dreams: [Dream] = []
    @Published var journalEntries: [JournalEntry] = []

    private let authenticator: BiometricAuthenticating = BiometricAuthenticator()
    private let dreamStore = DreamStore()
    // Exposed for view access
    var store: DreamStore { dreamStore }

    // MARK: Unlock

    func unlockApp() async {
        do {
            if authenticator.canEvaluateBiometrics() {
                let authorized = try await authenticator.evaluateBiometrics(
                    reason: "Unlock DreamTracker."
                )
                guard authorized else {
                    throw SecurityError.authenticationFailed(reason: "Not authorized.")
                }
            } else {
                let context = LAContext()
                var error: NSError?
                guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                    throw SecurityError.passcodeNotSet
                }
                let authorized = try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: "Unlock DreamTracker."
                )
                guard authorized else {
                    throw SecurityError.authenticationFailed(reason: "Passcode failed.")
                }
            }

            // Seed if first launch
            try? await dreamStore.seedIfEmpty()

            let loadedDreams = (try? await dreamStore.fetchDreams()) ?? []
            let loadedEntries = (try? await dreamStore.fetchEntries()) ?? []

            await MainActor.run {
                self.dreams = loadedDreams
                self.journalEntries = loadedEntries
                self.isUnlocked = true
                self.errorMessage = nil
                // Defer Store setup to after UI is visible
                self.storeManager.setupIfNeeded()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isUnlocked = false
            }
        }
    }

    func lockApp() {
        storeManager.teardown()
        isUnlocked = false
        dreams = []
        journalEntries = []
        errorMessage = nil
    }

    // MARK: Dreams

    func addDream(title: String, horizon: TimeHorizon) {
        let dream = Dream(title: title, horizon: horizon)
        dreams.append(dream)
        Task {
            try? await dreamStore.saveDream(dream)
        }
    }

    func toggleDream(id: UUID) {
        guard let idx = dreams.firstIndex(where: { $0.id == id }) else { return }
        dreams[idx].isCompleted.toggle()
        dreams[idx].completedAt = dreams[idx].isCompleted ? Date() : nil
        Task {
            try? await dreamStore.toggleDream(id: id)
        }
    }

    func updateDream(id: UUID, title: String, notes: String, horizon: TimeHorizon) {
        guard let idx = dreams.firstIndex(where: { $0.id == id }) else { return }
        dreams[idx].title = title
        dreams[idx].notes = notes
        dreams[idx].horizon = horizon
        Task {
            try? await dreamStore.saveDream(dreams[idx])
        }
    }

    func moveDream(from source: IndexSet, to destination: Int, horizon: TimeHorizon) {
        var horizonDreams = dreams
            .filter { $0.horizon == horizon }
            .sorted { $0.order < $1.order }
        horizonDreams.move(fromOffsets: source, toOffset: destination)
        for (i, var dream) in horizonDreams.enumerated() {
            dream.order = i
            if let idx = dreams.firstIndex(where: { $0.id == dream.id }) {
                dreams[idx] = dream
                Task { try? await dreamStore.saveDream(dream) }
            }
        }
    }

    func deleteDream(id: UUID) {
        dreams.removeAll { $0.id == id }
        Task {
            try? await dreamStore.deleteDream(id: id)
        }
    }

    func decomposeDream(parentID: UUID, subDreams: [(title: String, horizon: TimeHorizon)]) {
        var orderByHorizon: [TimeHorizon: Int] = [:]
        for horizon in TimeHorizon.allCases {
            orderByHorizon[horizon] = dreams.filter { $0.horizon == horizon }.count
        }
        for sub in subDreams {
            let order = orderByHorizon[sub.horizon] ?? 0
            let dream = Dream(title: sub.title, horizon: sub.horizon, order: order, parentID: parentID)
            dreams.append(dream)
            orderByHorizon[sub.horizon] = order + 1
            Task {
                try? await dreamStore.saveDream(dream)
            }
        }
    }

    // MARK: Journal

    func addJournalEntry(content: String) {
        let entry = JournalEntry(content: content)
        journalEntries.insert(entry, at: 0)
        Task {
            try? await dreamStore.saveEntry(entry)
        }
    }

    // MARK: Delete All

    func deleteAllData() async {
        try? dreamStore.destroyAll()
        await MainActor.run {
            dreams = []
            journalEntries = []
        }
    }
}
