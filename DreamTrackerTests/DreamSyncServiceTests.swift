import XCTest
import Network
@testable import DreamTracker

final class DreamSyncServiceTests: XCTestCase {
    private var tempURL: URL!
    private var secureStore: SecureStore!
    private var mockAPIClient: MockAPIClient!
    private var mockKeychain: MockKeychainManager!
    private var sut: DreamSyncService!
    
    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        secureStore = SecureStore(storeURL: tempURL)
        mockAPIClient = MockAPIClient()
        mockKeychain = MockKeychainManager()
        sut = DreamSyncService(
            secureStore: secureStore,
            apiClient: mockAPIClient,
            keychain: mockKeychain
        )
    }
    
    override func tearDown() {
        try? secureStore?.destroy()
        secureStore = nil
        mockAPIClient = nil
        mockKeychain = nil
        sut = nil
        super.tearDown()
    }
    
    func testSyncPullingAndLWWConflictResolution() async throws {
        // 1. Setup local dreams
        let localDate1 = Date().addingTimeInterval(-100)
        let localDate2 = Date().addingTimeInterval(-100)
        
        let localDream1 = Dream(
            id: UUID(),
            title: "Local Dream 1",
            content: "Local Content 1",
            lucidityScore: 3,
            isLucid: false,
            updatedAt: localDate1,
            isDeleted: false,
            isPendingSync: false
        )
        let localDream2 = Dream(
            id: UUID(),
            title: "Local Dream 2",
            content: "Local Content 2",
            lucidityScore: 4,
            isLucid: true,
            updatedAt: localDate2,
            isDeleted: false,
            isPendingSync: false
        )
        
        try await secureStore.saveDream(localDream1)
        try await secureStore.saveDream(localDream2)
        
        // 2. Setup remote dreams
        // Remote 1 has a newer updatedAt -> Remote wins
        let remoteDate1 = Date()
        let remoteDream1 = Dream(
            id: localDream1.id,
            title: "Remote Dream 1 (Winner)",
            content: "Remote Content 1",
            lucidityScore: 5,
            isLucid: true,
            updatedAt: remoteDate1,
            isDeleted: false,
            isPendingSync: false
        )
        // Remote 2 has an older updatedAt -> Local wins
        let remoteDate2 = Date().addingTimeInterval(-200)
        let remoteDream2 = Dream(
            id: localDream2.id,
            title: "Remote Dream 2 (Loser)",
            content: "Remote Content 2",
            lucidityScore: 1,
            isLucid: false,
            updatedAt: remoteDate2,
            isDeleted: false,
            isPendingSync: false
        )
        // Remote 3 is a brand new dream -> Saved locally
        let remoteDream3 = Dream(
            id: UUID(),
            title: "Remote Dream 3 (New)",
            content: "Remote Content 3",
            lucidityScore: 3,
            isLucid: true,
            updatedAt: Date(),
            isDeleted: false,
            isPendingSync: false
        )
        
        mockAPIClient.pullResponse = [remoteDream1, remoteDream2, remoteDream3]
        mockAPIClient.pushResponse = []
        
        // Run synchronization
        try await sut.synchronize()
        
        // Verify results
        let finalLocalDreams = try await secureStore.fetchAllDreams(includeDeleted: true)
        
        // Local dream 1 should be updated (remote wins)
        let finalDream1 = finalLocalDreams.first(where: { $0.id == localDream1.id })
        XCTAssertNotNil(finalDream1)
        XCTAssertEqual(finalDream1?.title, "Remote Dream 1 (Winner)")
        XCTAssertEqual(finalDream1?.lucidityScore, 5)
        
        // Local dream 2 should NOT be updated (local wins)
        let finalDream2 = finalLocalDreams.first(where: { $0.id == localDream2.id })
        XCTAssertNotNil(finalDream2)
        XCTAssertEqual(finalDream2?.title, "Local Dream 2")
        XCTAssertEqual(finalDream2?.lucidityScore, 4)
        
        // Remote dream 3 should be inserted
        let finalDream3 = finalLocalDreams.first(where: { $0.id == remoteDream3.id })
        XCTAssertNotNil(finalDream3)
        XCTAssertEqual(finalDream3?.title, "Remote Dream 3 (New)")
    }
    
    func testSyncPushingAndDeletionPurges() async throws {
        // 1. Setup local dreams pending sync
        let normalDream = Dream(
            id: UUID(),
            title: "Local Unsynced",
            content: "Need to push",
            lucidityScore: 2,
            isLucid: false,
            updatedAt: Date(),
            isDeleted: false,
            isPendingSync: true
        )
        let deletedDream = Dream(
            id: UUID(),
            title: "Local Deleted",
            content: "Need to purge",
            lucidityScore: 4,
            isLucid: true,
            updatedAt: Date(),
            isDeleted: true,
            isPendingSync: true
        )
        
        try await secureStore.saveDream(normalDream)
        try await secureStore.saveDream(deletedDream)
        
        // Mock responses
        mockAPIClient.pullResponse = []
        // Push acknowledges both changes
        mockAPIClient.pushResponse = [normalDream, deletedDream]
        
        try await sut.synchronize()
        
        // Verify normal dream is no longer pending sync
        let allLocal = try await secureStore.fetchAllDreams(includeDeleted: true)
        let resultNormal = allLocal.first(where: { $0.id == normalDream.id })
        XCTAssertNotNil(resultNormal)
        XCTAssertFalse(resultNormal!.isPendingSync)
        
        // Verify deleted dream is permanently deleted (purged)
        let resultDeleted = allLocal.first(where: { $0.id == deletedDream.id })
        XCTAssertNil(resultDeleted)
        
        // Verify last sync timestamp was updated in Keychain
        let timestampData = try mockKeychain.retrieve(key: "last_sync_timestamp")
        XCTAssertNotNil(timestampData)
        let timestampStr = String(data: timestampData!, encoding: .utf8)
        XCTAssertNotNil(timestampStr)
        XCTAssertNotNil(ISO8601DateFormatter().date(from: timestampStr!))
    }
    
    func testOfflineErrorHandling() async throws {
        // Setup API client to throw connection error
        mockAPIClient.shouldThrowError = NetworkError.requestFailed(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))
        
        do {
            try await sut.synchronize()
            XCTFail("Should throw offline network error")
        } catch {
            // Verify error was propagated
            XCTAssertTrue(error is NetworkError)
        }
    }
}

// MARK: - Mocks

class MockKeychainManager: KeychainManagerProtocol {
    var store: [String: Data] = [:]
    
    func save(key: String, data: Data) throws {
        store[key] = data
    }
    
    func retrieve(key: String) throws -> Data? {
        return store[key]
    }
    
    func delete(key: String) throws {
        store.removeValue(forKey: key)
    }
}

class MockAPIClient: NetworkClientProtocol {
    var pullResponse: [Dream] = []
    var pushResponse: [Dream] = []
    var lastPulledSince: Date?
    var lastPushedChanges: [Dream] = []
    var shouldThrowError: Error?
    
    func request<T: Decodable>(_ route: APIRoute) async throws -> T {
        if let error = shouldThrowError {
            throw error
        }
        
        if let syncRoute = route as? DreamSyncRoute {
            switch syncRoute {
            case .pullUpdates(let since):
                lastPulledSince = since
                return pullResponse as! T
            case .pushUpdates(let changes):
                lastPushedChanges = changes
                return pushResponse as! T
            }
        }
        
        throw NetworkError.invalidURL
    }
}
