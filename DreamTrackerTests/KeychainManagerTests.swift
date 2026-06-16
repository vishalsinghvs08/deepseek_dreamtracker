import XCTest
@testable import DreamTracker

final class KeychainManagerTests: XCTestCase {
    private var sut: KeychainManager!
    private let testKey = "test.keychain.key"
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = KeychainManager(service: "com.dreamtracker.tests.keychain", requireAuthentication: false)
        try? sut.delete(key: testKey)
    }
    
    override func tearDownWithError() throws {
        try? sut.delete(key: testKey)
        sut = nil
        try super.tearDownWithError()
    }
    
    func testSaveAndRetrieveSuccess() throws {
        let originalString = "SuperSecretData"
        let data = try XCTUnwrap(originalString.data(using: .utf8))
        
        try sut.save(key: testKey, data: data)
        
        let retrievedData = try sut.retrieve(key: testKey)
        let unwrappedData = try XCTUnwrap(retrievedData)
        let retrievedString = String(data: unwrappedData, encoding: .utf8)
        
        XCTAssertEqual(retrievedString, originalString)
    }
    
    func testSaveOverwriteSuccess() throws {
        let firstString = "FirstSecretData"
        let firstData = try XCTUnwrap(firstString.data(using: .utf8))
        try sut.save(key: testKey, data: firstData)
        
        let secondString = "SecondSecretData"
        let secondData = try XCTUnwrap(secondString.data(using: .utf8))
        try sut.save(key: testKey, data: secondData)
        
        let retrievedData = try sut.retrieve(key: testKey)
        let unwrappedData = try XCTUnwrap(retrievedData)
        let retrievedString = String(data: unwrappedData, encoding: .utf8)
        
        XCTAssertEqual(retrievedString, secondString)
    }
    
    func testRetrieveNotFoundReturnsNil() throws {
        let retrievedData = try sut.retrieve(key: "nonexistent.key")
        XCTAssertNil(retrievedData)
    }
    
    func testDeleteSuccess() throws {
        let data = try XCTUnwrap("DeleteMe".data(using: .utf8))
        try sut.save(key: testKey, data: data)
        
        try sut.delete(key: testKey)
        
        let retrievedData = try sut.retrieve(key: testKey)
        XCTAssertNil(retrievedData)
    }
    
    func testKeychainManagerRapidOperations() throws {
        let numIterations = 200
        let service = "com.dreamtracker.tests.keychain"
        let manager = KeychainManager(service: service, requireAuthentication: false)
        
        let startTime = Date()
        for i in 0..<numIterations {
            let key = "rapid.key.\(i)"
            let originalString = "SecretValue-\(i)"
            let data = originalString.data(using: .utf8)!
            
            try manager.save(key: key, data: data)
            let retrieved = try manager.retrieve(key: key)
            XCTAssertNotNil(retrieved)
            let retrievedString = String(data: retrieved!, encoding: .utf8)
            XCTAssertEqual(retrievedString, originalString)
            try manager.delete(key: key)
            let retrievedAfterDelete = try manager.retrieve(key: key)
            XCTAssertNil(retrievedAfterDelete)
        }
        let duration = Date().timeIntervalSince(startTime)
        print("Performed \(numIterations) Keychain save/retrieve/delete iterations in \(duration) seconds")
    }
    
    func testKeychainManagerConcurrency() async throws {
        let numTasks = 50
        let service = "com.dreamtracker.tests.keychain.concurrent"
        let manager = KeychainManager(service: service, requireAuthentication: false)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0..<numTasks {
                group.addTask {
                    let key = "concurrent.key.\(i)"
                    let originalString = "SecretValue-\(i)"
                    let data = originalString.data(using: .utf8)!
                    
                    for _ in 0..<5 {
                        try manager.save(key: key, data: data)
                        let retrieved = try manager.retrieve(key: key)
                        XCTAssertNotNil(retrieved)
                        try manager.delete(key: key)
                    }
                }
            }
            try await group.waitForAll()
        }
    }
}
