import Foundation
import Network

public protocol DreamSyncServiceProtocol: AnyObject {
    func synchronize() async throws
}

public actor DreamSyncService: DreamSyncServiceProtocol {
    private let secureStore: SecureStoreProtocol
    private let apiClient: NetworkClientProtocol
    private let keychain: KeychainManagerProtocol
    private let pathMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.dreamtracker.sync.monitor")
    
    private var isSyncing = false
    
    public init(
        secureStore: SecureStoreProtocol,
        apiClient: NetworkClientProtocol,
        keychain: KeychainManagerProtocol
    ) {
        self.secureStore = secureStore
        self.apiClient = apiClient
        self.keychain = keychain
        self.pathMonitor = NWPathMonitor()
        
        self.pathMonitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                Task { [weak self] in
                    try? await self?.synchronize()
                }
            }
        }
        self.pathMonitor.start(queue: monitorQueue)
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    public func synchronize() async throws {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        let formatter = ISO8601DateFormatter()
        
        // 1. Read last sync timestamp from Keychain
        var lastSyncDate = Date(timeIntervalSince1970: 0)
        if let data = try? keychain.retrieve(key: "last_sync_timestamp"),
           let dateStr = String(data: data, encoding: .utf8),
           let date = formatter.date(from: dateStr) {
            lastSyncDate = date
        }
        
        // 2. Pull remote changes
        let remoteDreams: [Dream] = try await apiClient.request(DreamSyncRoute.pullUpdates(since: lastSyncDate))
        
        // 3. Resolve conflicts (LWW)
        let localDreams = try await secureStore.fetchAllDreams(includeDeleted: true)
        
        for remote in remoteDreams {
            if let local = localDreams.first(where: { $0.id == remote.id }) {
                // Remote wins if remote.updatedAt > local.updatedAt
                if remote.updatedAt > local.updatedAt {
                    try await secureStore.saveDream(remote)
                }
            } else {
                // No local copy, save remote dream
                try await secureStore.saveDream(remote)
            }
        }
        
        // 4. Push local changes
        let pendingDreams = try await secureStore.fetchPendingSyncDreams()
        if !pendingDreams.isEmpty {
            let pushedDreams: [Dream] = try await apiClient.request(DreamSyncRoute.pushUpdates(changes: pendingDreams))
            
            for dream in pushedDreams {
                if dream.isDeleted {
                    try await secureStore.permanentlyDeleteDream(id: dream.id)
                } else {
                    var updatedDream = dream
                    updatedDream.isPendingSync = false
                    try await secureStore.saveDream(updatedDream)
                }
            }
        }
        
        // 5. Update last sync timestamp in Keychain
        let nowString = formatter.string(from: Date())
        if let data = nowString.data(using: .utf8) {
            try keychain.save(key: "last_sync_timestamp", data: data)
        }
    }
}
