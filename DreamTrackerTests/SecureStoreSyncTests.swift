import XCTest
@testable import DreamTracker

final class SecureStoreSyncTests: XCTestCase {
    private var tempURL: URL!
    private var sut: SecureStore!
    
    override func setUp() {
        super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        sut = SecureStore(storeURL: tempURL)
    }
    
    override func tearDown() {
        try? sut?.destroy()
        sut = nil
        super.tearDown()
    }
    
    func testMetadataCRUD() async throws {
        let originalDate = Date().addingTimeInterval(-1000)
        let dream = Dream(
            title: "Test Metadata",
            content: "Testing metadata CRUD",
            date: Date(),
            lucidityScore: 3,
            isLucid: false,
            tags: ["test"],
            updatedAt: originalDate,
            isDeleted: false,
            isPendingSync: true
        )
        
        try await sut.saveDream(dream)
        
        let fetched = try await sut.fetchAllDreams(includeDeleted: true)
        XCTAssertEqual(fetched.count, 1)
        
        let retrieved = fetched[0]
        XCTAssertEqual(retrieved.id, dream.id)
        XCTAssertEqual(retrieved.isDeleted, false)
        XCTAssertEqual(retrieved.isPendingSync, true)
        XCTAssertEqual(retrieved.updatedAt.timeIntervalSince1970, originalDate.timeIntervalSince1970, accuracy: 1.0)
        
        // Update metadata
        var updated = retrieved
        updated.isPendingSync = false
        let updatedDate = Date()
        updated.updatedAt = updatedDate
        try await sut.saveDream(updated)
        
        let fetchedUpdated = try await sut.fetchAllDreams(includeDeleted: true)
        XCTAssertEqual(fetchedUpdated.count, 1)
        XCTAssertEqual(fetchedUpdated[0].isPendingSync, false)
        XCTAssertEqual(fetchedUpdated[0].updatedAt.timeIntervalSince1970, updatedDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testSoftDeletion() async throws {
        let dream = Dream(
            title: "Soft Delete",
            content: "Going to be soft deleted",
            lucidityScore: 2,
            isLucid: false
        )
        try await sut.saveDream(dream)
        
        // Active dream shows in fetchDreams
        var active = try await sut.fetchDreams()
        XCTAssertEqual(active.count, 1)
        
        // Soft delete
        try await sut.deleteDream(id: dream.id)
        
        // Excluded from fetchDreams
        active = try await sut.fetchDreams()
        XCTAssertEqual(active.count, 0)
        
        // Included in fetchAllDreams(includeDeleted: true)
        let all = try await sut.fetchAllDreams(includeDeleted: true)
        XCTAssertEqual(all.count, 1)
        XCTAssertTrue(all[0].isDeleted)
        XCTAssertTrue(all[0].isPendingSync)
        XCTAssertGreaterThan(all[0].updatedAt, dream.updatedAt)
    }
    
    func testHardDeletion() async throws {
        let dream = Dream(
            title: "Hard Delete",
            content: "Going to be hard deleted",
            lucidityScore: 4,
            isLucid: true
        )
        try await sut.saveDream(dream)
        
        // Soft delete first
        try await sut.deleteDream(id: dream.id)
        
        // Verify it still exists in all
        var all = try await sut.fetchAllDreams(includeDeleted: true)
        XCTAssertEqual(all.count, 1)
        
        // Hard delete
        try await sut.permanentlyDeleteDream(id: dream.id)
        
        // Verify it is completely gone
        all = try await sut.fetchAllDreams(includeDeleted: true)
        XCTAssertEqual(all.count, 0)
    }
}
