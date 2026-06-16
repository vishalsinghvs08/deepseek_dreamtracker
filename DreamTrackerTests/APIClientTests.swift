import XCTest
import CryptoKit
@testable import DreamTracker

final class APIClientTests: XCTestCase {
    private var mockKeychain: APIClientMockKeychainManager!
    private var mockAppAttest: MockAppAttestManager!
    private var apiClient: APIClient!
    private var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        print("DEBUG_HASH: " + Data(CryptoKit.SHA256.hash(data: "challenge-data".data(using: .utf8)!)).base64EncodedString())
        mockKeychain = APIClientMockKeychainManager()
        mockAppAttest = MockAppAttestManager()
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        
        apiClient = APIClient(
            baseURL: URL(string: "https://api.test.com")!,
            keychain: mockKeychain,
            appAttestManager: mockAppAttest,
            session: mockSession
        )
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        mockKeychain = nil
        mockAppAttest = nil
        apiClient = nil
        super.tearDown()
    }
    
    func testPerformSuccess() async throws {
        struct MockResponse: Codable, Equatable {
            let id: String
        }
        
        let expectedResponse = MockResponse(id: "123")
        let responseData = try JSONEncoder().encode(expectedResponse)
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.test.com/test")
            XCTAssertEqual(request.httpMethod, "GET")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseData)
        }
        
        let endpoint = Endpoint(path: "test", method: .get, requiresAuth: false)
        let result: MockResponse = try await apiClient.request(endpoint)
        XCTAssertEqual(result, expectedResponse)
    }
    
    func testHeaderInjection() async throws {
        struct EmptyResponse: Decodable {}
        
        // Setup credentials
        try mockKeychain.save(key: "access_token", data: "my-jwt-token".data(using: .utf8)!)
        try mockKeychain.save(key: "app_attest_key_id", data: "my-key-id".data(using: .utf8)!)
        
        mockAppAttest.isSupported = true
        mockAppAttest.mockAssertion = "my-assertion-payload".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer my-jwt-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Attest-Key-Id"), "my-key-id")
            XCTAssertNotNil(request.value(forHTTPHeaderField: "X-App-Attest-Assertion"))
            XCTAssertNotNil(request.value(forHTTPHeaderField: "X-App-Attest-Client-Data"))
            XCTAssertNotNil(request.value(forHTTPHeaderField: "X-App-Attest-Timestamp"))
            XCTAssertNotNil(request.value(forHTTPHeaderField: "X-App-Attest-Nonce"))
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, "{}".data(using: .utf8)!)
        }
        
        let endpoint = Endpoint(path: "write", method: .post, body: "body".data(using: .utf8), requiresAuth: true, requiresAppAttest: true)
        let _: EmptyResponse = try await apiClient.request(endpoint)
    }
    
    func testTokenRefreshOn401() async throws {
        struct MockResponse: Codable, Equatable {
            let value: String
        }
        
        // Setup original token and refresh token
        try mockKeychain.save(key: "access_token", data: "expired-token".data(using: .utf8)!)
        try mockKeychain.save(key: "refresh_token", data: "valid-refresh-token".data(using: .utf8)!)
        
        var requestCount = 0
        
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            
            if request.url?.path == "/test" {
                if request.value(forHTTPHeaderField: "Authorization") == "Bearer expired-token" {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 401,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    return (response, Data())
                } else if request.value(forHTTPHeaderField: "Authorization") == "Bearer new-token" {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    let responseData = try! JSONEncoder().encode(MockResponse(value: "refreshed-success"))
                    return (response, responseData)
                }
            } else if request.url?.path == "/auth/refresh" {
                XCTAssertEqual(request.httpMethod, "POST")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                let refreshResp = TokenRefreshResponse(accessToken: "new-token", refreshToken: "new-refresh-token")
                let responseData = try! JSONEncoder().encode(refreshResp)
                return (response, responseData)
            }
            
            fatalError("Unexpected request")
        }
        
        let endpoint = Endpoint(path: "test", method: .get, requiresAuth: true)
        let result: MockResponse = try await apiClient.request(endpoint)
        
        XCTAssertEqual(result.value, "refreshed-success")
        XCTAssertEqual(requestCount, 3) // 1st GET (401) -> POST refresh (200) -> 2nd GET (200)
        
        // Verify keychain updated
        let access = try mockKeychain.retrieve(key: "access_token")
        let refresh = try mockKeychain.retrieve(key: "refresh_token")
        XCTAssertEqual(access, "new-token".data(using: .utf8))
        XCTAssertEqual(refresh, "new-refresh-token".data(using: .utf8))
    }

    func testConcurrentTokenRefresh() async throws {
        struct MockResponse: Codable, Equatable {
            let value: String
        }
        
        // Setup original token and refresh token
        try mockKeychain.save(key: "access_token", data: "expired-token".data(using: .utf8)!)
        try mockKeychain.save(key: "refresh_token", data: "valid-refresh-token".data(using: .utf8)!)
        
        final class Counter: @unchecked Sendable {
            private let lock = NSLock()
            var refreshCount = 0
            var requestCount = 0
            
            func incrementRefresh() {
                lock.lock()
                defer { lock.unlock() }
                refreshCount += 1
            }
            
            func incrementRequest() {
                lock.lock()
                defer { lock.unlock() }
                requestCount += 1
            }
        }
        
        let counter = Counter()
        
        MockURLProtocol.requestHandler = { request in
            counter.incrementRequest()
            
            if request.url?.path == "/test" {
                if request.value(forHTTPHeaderField: "Authorization") == "Bearer expired-token" {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 401,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    return (response, Data())
                } else if request.value(forHTTPHeaderField: "Authorization") == "Bearer new-token" {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    let responseData = try! JSONEncoder().encode(MockResponse(value: "refreshed-success"))
                    return (response, responseData)
                }
            } else if request.url?.path == "/auth/refresh" {
                counter.incrementRefresh()
                Thread.sleep(forTimeInterval: 0.1)
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                let refreshResp = TokenRefreshResponse(accessToken: "new-token", refreshToken: "new-refresh-token")
                let responseData = try! JSONEncoder().encode(refreshResp)
                return (response, responseData)
            }
            
            fatalError("Unexpected request")
        }
        
        let endpoint = Endpoint(path: "test", method: .get, requiresAuth: true)
        
        try await withThrowingTaskGroup(of: MockResponse.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    return try await self.apiClient.request(endpoint)
                }
            }
            
            for try await result in group {
                XCTAssertEqual(result.value, "refreshed-success")
            }
        }
        
        XCTAssertEqual(counter.refreshCount, 1)
        XCTAssertEqual(counter.requestCount, 41)
        
        // Verify keychain updated
        let access = try mockKeychain.retrieve(key: "access_token")
        let refresh = try mockKeychain.retrieve(key: "refresh_token")
        XCTAssertEqual(access, "new-token".data(using: .utf8))
        XCTAssertEqual(refresh, "new-refresh-token".data(using: .utf8))
    }

    func testAppAttestThrowsWhenUnsupported() async throws {
        struct EmptyResponse: Decodable {}
        
        // Setup credentials
        try mockKeychain.save(key: "access_token", data: "my-jwt-token".data(using: .utf8)!)
        try mockKeychain.save(key: "app_attest_key_id", data: "my-key-id".data(using: .utf8)!)
        
        let realAppAttestManager = AppAttestManager()
        
        apiClient = APIClient(
            baseURL: URL(string: "https://api.test.com")!,
            keychain: mockKeychain,
            appAttestManager: realAppAttestManager,
            session: mockSession
        )
        
        let endpoint = Endpoint(path: "write", method: .post, body: "body".data(using: .utf8), requiresAuth: true, requiresAppAttest: true)
        
        do {
            let _: EmptyResponse = try await apiClient.request(endpoint)
            XCTFail("Expected appAttestUnsupported error, but request succeeded")
        } catch NetworkError.appAttestUnsupported {
            // Expected
        } catch {
            XCTFail("Expected appAttestUnsupported error, but got: \(error)")
        }
    }
    
    func testPerformSuccessWith2xxCodes() async throws {
        struct MockResponse: Codable, Equatable {
            let id: String?
        }
        
        // Test 201 Created
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, #"{"id":"201"}"#.data(using: .utf8)!)
        }
        
        let endpoint201 = Endpoint(path: "test", method: .post, requiresAuth: false)
        let result201: MockResponse = try await apiClient.request(endpoint201)
        XCTAssertEqual(result201.id, "201")
        
        // Test 204 No Content
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, #"{}"#.data(using: .utf8)!)
        }
        
        let endpoint204 = Endpoint(path: "test", method: .delete, requiresAuth: false)
        let _: MockResponse = try await apiClient.request(endpoint204)
    }
    
    func testTokenRefreshOn401With201Retry() async throws {
        struct MockResponse: Codable, Equatable {
            let value: String
        }
        
        try mockKeychain.save(key: "access_token", data: "expired-token".data(using: .utf8)!)
        try mockKeychain.save(key: "refresh_token", data: "valid-refresh-token".data(using: .utf8)!)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/test" {
                if request.value(forHTTPHeaderField: "Authorization") == "Bearer expired-token" {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 401,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    return (response, Data())
                } else if request.value(forHTTPHeaderField: "Authorization") == "Bearer new-token" {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 201,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    let responseData = try! JSONEncoder().encode(MockResponse(value: "refreshed-success-201"))
                    return (response, responseData)
                }
            } else if request.url?.path == "/auth/refresh" {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                let refreshResp = TokenRefreshResponse(accessToken: "new-token", refreshToken: "new-refresh-token")
                let responseData = try! JSONEncoder().encode(refreshResp)
                return (response, responseData)
            }
            fatalError("Unexpected request")
        }
        
        let endpoint = Endpoint(path: "test", method: .get, requiresAuth: true)
        let result: MockResponse = try await apiClient.request(endpoint)
        XCTAssertEqual(result.value, "refreshed-success-201")
    }
    
    func testTokenRefreshFailureClearsKeychain() async throws {
        try mockKeychain.save(key: "access_token", data: "expired-token".data(using: .utf8)!)
        try mockKeychain.save(key: "refresh_token", data: "invalid-refresh-token".data(using: .utf8)!)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/test" {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            } else if request.url?.path == "/auth/refresh" {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            }
            fatalError("Unexpected request")
        }
        
        struct EmptyResponse: Decodable {}
        let endpoint = Endpoint(path: "test", method: .get, requiresAuth: true)
        
        do {
            let _: EmptyResponse = try await apiClient.request(endpoint)
            XCTFail("Expected perform to fail due to refresh failure")
        } catch {
            let accessToken = try? mockKeychain.retrieve(key: "access_token")
            let refreshToken = try? mockKeychain.retrieve(key: "refresh_token")
            XCTAssertNil(accessToken)
            XCTAssertNil(refreshToken)
        }
    }
    
    func testAppAttestLazyRegistrationAndHeaderInjection() async throws {
        struct EmptyResponse: Decodable {}
        
        XCTAssertNil(try mockKeychain.retrieve(key: "app_attest_key_id"))
        mockAppAttest.isSupported = true
        mockAppAttest.mockKeyId = "newly-generated-key-id"
        mockAppAttest.mockAssertion = "new-assertion-data".data(using: .utf8)!
        
        try mockKeychain.save(key: "access_token", data: "my-jwt-token".data(using: .utf8)!)
        
        var challengeRequested = false
        var attestationRegistered = false
        var actualRequestPerformed = false
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.path == "/auth/attest-challenge" {
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer my-jwt-token")
                challengeRequested = true
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                let challengeResp = ChallengeResponse(challenge: "Y2hhbGxlbmdlLWRhdGE=")
                let responseData = try! JSONEncoder().encode(challengeResp)
                return (response, responseData)
                
            } else if request.url?.path == "/auth/register-attestation" {
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer my-jwt-token")
                attestationRegistered = true
                
                struct AttestRegisterBody: Codable {
                    let keyId: String
                    let attestation: String
                    let clientDataHash: String
                }
                
                let decoder = JSONDecoder()
                if let bodyData = request.httpBody ?? MockURLProtocol.retrieveBody(from: request),
                   let body = try? decoder.decode(AttestRegisterBody.self, from: bodyData) {
                    XCTAssertEqual(body.keyId, "newly-generated-key-id")
                    XCTAssertEqual(body.attestation, Data().base64EncodedString())
                    let expectedHash = Data(SHA256.hash(data: "challenge-data".data(using: .utf8)!))
                    XCTAssertEqual(body.clientDataHash, expectedHash.base64EncodedString())
                } else {
                    XCTFail("Failed to decode registration request body")
                }
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, "{}".data(using: .utf8)!)
                
            } else if request.url?.path == "/write" {
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer my-jwt-token")
                XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Attest-Key-Id"), "newly-generated-key-id")
                XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Attest-Assertion"), "new-assertion-data".data(using: .utf8)!.base64EncodedString())
                
                let bodyData = "body".data(using: .utf8)!
                let timestamp = request.value(forHTTPHeaderField: "X-App-Attest-Timestamp") ?? ""
                let nonce = request.value(forHTTPHeaderField: "X-App-Attest-Nonce") ?? ""
                
                struct ClientData: Codable {
                    let method: String
                    let path: String
                    let body: Data
                    let timestamp: String
                    let nonce: String
                }
                
                let clientData = ClientData(method: "POST", path: "write", body: bodyData, timestamp: timestamp, nonce: nonce)
                let encoder = JSONEncoder()
                encoder.outputFormatting = .sortedKeys
                let clientDataJSON = try! encoder.encode(clientData)
                let expectedClientHash = Data(SHA256.hash(data: clientDataJSON)).base64EncodedString()
                
                XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Attest-Client-Data"), expectedClientHash)
                
                actualRequestPerformed = true
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, "{}".data(using: .utf8)!)
            }
            
            fatalError("Unexpected request to path: \(request.url?.path ?? "")")
        }
        
        let endpoint = Endpoint(path: "write", method: .post, body: "body".data(using: .utf8), requiresAuth: true, requiresAppAttest: true)
        let _: EmptyResponse = try await apiClient.request(endpoint)
        
        XCTAssertTrue(challengeRequested)
        XCTAssertTrue(attestationRegistered)
        XCTAssertTrue(actualRequestPerformed)
        
        let storedKeyIdData = try mockKeychain.retrieve(key: "app_attest_key_id")
        XCTAssertNotNil(storedKeyIdData)
        if let storedKeyIdData = storedKeyIdData {
            XCTAssertEqual(String(data: storedKeyIdData, encoding: .utf8), "newly-generated-key-id")
        }
    }
}

// MARK: - Mock Helpers

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    static func retrieveBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        if let stream = request.httpBodyStream {
            stream.open()
            var data = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, count: read)
                } else {
                    break
                }
            }
            stream.close()
            return data
        }
        return nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler not set")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

private final class APIClientMockKeychainManager: KeychainManagerProtocol {
    private var store: [String: Data] = [:]
    
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

private final class MockAppAttestManager: AppAttestManagerProtocol {
    var isSupported: Bool = false
    var mockKeyId: String = "mock-key-id"
    var mockAssertion: Data = Data()
    
    func generateKey() async throws -> String {
        return mockKeyId
    }
    
    func attestKey(keyId: String, clientDataHash: Data) async throws -> Data {
        return Data()
    }
    
    func generateAssertion(keyId: String, clientDataHash: Data) async throws -> Data {
        return mockAssertion
    }
}
