import XCTest
@testable import DreamTracker

final class SecureStoreTests: XCTestCase {
    private var tempURL: URL!
    private var sut: SecureStore!
    
    private let testDream = Dream(
        title: "Flying",
        content: "I was flying over mountains",
        date: Date(),
        lucidityScore: 4,
        isLucid: true,
        tags: ["flying", "nature"]
    )
    
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
    
    func testSaveAndFetchDream() async throws {
        try await sut.saveDream(testDream)
        
        let fetched = try await sut.fetchDreams()
        XCTAssertEqual(fetched.count, 1)
        
        let retrieved = fetched[0]
        XCTAssertEqual(retrieved.id, testDream.id)
        XCTAssertEqual(retrieved.title, testDream.title)
        XCTAssertEqual(retrieved.content, testDream.content)
        XCTAssertEqual(retrieved.lucidityScore, testDream.lucidityScore)
        XCTAssertEqual(retrieved.isLucid, testDream.isLucid)
        XCTAssertEqual(retrieved.tags, testDream.tags)
        // Check date comparison within a small window
        XCTAssertEqual(retrieved.date.timeIntervalSince1970, testDream.date.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testSaveOverwriteDream() async throws {
        try await sut.saveDream(testDream)
        
        var modifiedDream = testDream
        modifiedDream.title = "Swimming"
        modifiedDream.content = "Swimming in a warm lake"
        modifiedDream.lucidityScore = 2
        
        try await sut.saveDream(modifiedDream)
        
        let fetched = try await sut.fetchDreams()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].title, "Swimming")
        XCTAssertEqual(fetched[0].content, "Swimming in a warm lake")
        XCTAssertEqual(fetched[0].lucidityScore, 2)
    }
    
    func testDeleteDream() async throws {
        try await sut.saveDream(testDream)
        
        let secondDream = Dream(
            title: "Exam",
            content: "Forgot to study for math",
            date: Date().addingTimeInterval(60),
            lucidityScore: 1,
            isLucid: false,
            tags: ["stress"]
        )
        try await sut.saveDream(secondDream)
        
        var fetched = try await sut.fetchDreams()
        XCTAssertEqual(fetched.count, 2)
        
        try await sut.deleteDream(id: testDream.id)
        
        fetched = try await sut.fetchDreams()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].id, secondDream.id)
    }
    
    func testFetchSortedByDateDescending() async throws {
        let now = Date()
        
        let dreamOld = Dream(title: "Old", content: "Old", date: now.addingTimeInterval(-100), lucidityScore: 3, isLucid: false)
        let dreamNew = Dream(title: "New", content: "New", date: now.addingTimeInterval(100), lucidityScore: 3, isLucid: false)
        let dreamMid = Dream(title: "Mid", content: "Mid", date: now, lucidityScore: 3, isLucid: false)
        
        try await sut.saveDream(dreamOld)
        try await sut.saveDream(dreamNew)
        try await sut.saveDream(dreamMid)
        
        let fetched = try await sut.fetchDreams()
        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(fetched[0].title, "New")
        XCTAssertEqual(fetched[1].title, "Mid")
        XCTAssertEqual(fetched[2].title, "Old")
    }
    
    func testSecureStoreConcurrency() async throws {
        let numTasks = 100
        let dreamsToSave = (0..<numTasks).map { i in
            Dream(
                title: "Concurrent Dream \(i)",
                content: "Content \(i)",
                date: Date().addingTimeInterval(TimeInterval(i)),
                lucidityScore: (i % 5) + 1,
                isLucid: i % 2 == 0,
                tags: ["tag\(i)"]
            )
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for dream in dreamsToSave {
                group.addTask {
                    // 1. Write the dream
                    try await self.sut.saveDream(dream)
                    
                    // 2. Query dreams
                    let fetched = try await self.sut.fetchDreams()
                    XCTAssertTrue(fetched.contains(where: { $0.id == dream.id }))
                    
                    // 3. Delete the dream
                    try await self.sut.deleteDream(id: dream.id)
                }
            }
            try await group.waitForAll()
        }
        
        let finalDreams = try await sut.fetchDreams()
        XCTAssertEqual(finalDreams.count, 0)
    }
    
    func testSecureStoreScale() async throws {
        let count = 500
        var dreams: [Dream] = []
        for i in 0..<count {
            dreams.append(Dream(
                title: "Scale Dream \(i)",
                content: "Scale Content \(i)",
                date: Date().addingTimeInterval(TimeInterval(-i)),
                lucidityScore: (i % 5) + 1,
                isLucid: i % 2 == 0,
                tags: ["scale", "tag\(i)"]
            ))
        }
        
        let startTime = Date()
        for dream in dreams {
            try await sut.saveDream(dream)
        }
        let saveDuration = Date().timeIntervalSince(startTime)
        print("Saved \(count) dreams sequentially in \(saveDuration) seconds")
        
        let fetchStart = Date()
        let fetched = try await sut.fetchDreams()
        let fetchDuration = Date().timeIntervalSince(fetchStart)
        print("Fetched \(fetched.count) dreams in \(fetchDuration) seconds")
        
        XCTAssertEqual(fetched.count, count)
        
        let deleteStart = Date()
        for dream in dreams {
            try await sut.deleteDream(id: dream.id)
        }
        let deleteDuration = Date().timeIntervalSince(deleteStart)
        print("Deleted \(count) dreams sequentially in \(deleteDuration) seconds")
        
        let finalFetched = try await sut.fetchDreams()
        XCTAssertEqual(finalFetched.count, 0)
    }
}
