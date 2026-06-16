import XCTest
import Combine
@testable import DreamTracker

@MainActor
final class AuthServiceTests: XCTestCase {
    private var mockAPIClient: AuthServiceMockAPIClient!
    private var mockKeychain: AuthServiceMockKeychainManager!
    private var authService: AuthService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = AuthServiceMockAPIClient()
        mockKeychain = AuthServiceMockKeychainManager()
        authService = AuthService(apiClient: mockAPIClient, keychain: mockKeychain)
        cancellables = []
    }
    
    override func tearDown() {
        mockAPIClient = nil
        mockKeychain = nil
        authService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testLoginSuccess() async throws {
        let expectedResponse = AuthResponse(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            userIdentifier: "mock-user-id"
        )
        mockAPIClient.result = .success(expectedResponse)
        
        var states: [AuthState] = []
        authService.authStatePublisher
            .sink { states.append($0) }
            .store(in: &cancellables)
        
        try await authService.loginWithApple(identityToken: "id-token", authorizationCode: "auth-code")
        
        XCTAssertEqual(authService.authState, .authenticated)
        XCTAssertEqual(states, [.unauthenticated, .authenticating, .authenticated])
        
        // Verify Keychain storage
        let savedAccess = try mockKeychain.retrieve(key: "access_token")
        let savedRefresh = try mockKeychain.retrieve(key: "refresh_token")
        let savedUser = try mockKeychain.retrieve(key: "user_identifier")
        
        XCTAssertEqual(savedAccess, "mock-access-token".data(using: .utf8))
        XCTAssertEqual(savedRefresh, "mock-refresh-token".data(using: .utf8))
        XCTAssertEqual(savedUser, "mock-user-id".data(using: .utf8))
    }
    
    func testLoginFailure() async throws {
        mockAPIClient.result = .failure(NetworkError.badResponse(statusCode: 400))
        
        var states: [AuthState] = []
        authService.authStatePublisher
            .sink { states.append($0) }
            .store(in: &cancellables)
        
        do {
            try await authService.loginWithApple(identityToken: "id-token", authorizationCode: "auth-code")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
        
        if case .error = authService.authState {
            // Success
        } else {
            XCTFail("Expected .error authState, got \(authService.authState)")
        }
    }
    
    func testLogout() throws {
        // Pre-populate keychain
        try mockKeychain.save(key: "access_token", data: "token".data(using: .utf8)!)
        
        // Re-init authService to detect token
        authService = AuthService(apiClient: mockAPIClient, keychain: mockKeychain)
        XCTAssertEqual(authService.authState, .authenticated)
        
        try authService.logout()
        
        XCTAssertEqual(authService.authState, .unauthenticated)
        XCTAssertNil(try mockKeychain.retrieve(key: "access_token"))
    }
    
    func testCredentialsLoginSuccess() async throws {
        let expectedResponse = AuthResponse(
            accessToken: "credentials-access-token",
            refreshToken: "credentials-refresh-token",
            userIdentifier: "credentials-user-id"
        )
        mockAPIClient.result = .success(expectedResponse)
        
        var states: [AuthState] = []
        authService.authStatePublisher
            .sink { states.append($0) }
            .store(in: &cancellables)
        
        let credentials = Credentials(email: "test@example.com", password: "secure-password")
        try await authService.login(credentials: credentials)
        
        XCTAssertEqual(authService.authState, .authenticated)
        XCTAssertEqual(states, [.unauthenticated, .authenticating, .authenticated])
        
        // Verify route
        XCTAssertEqual(mockAPIClient.lastRoute?.path, "auth/login")
        XCTAssertEqual(mockAPIClient.lastRoute?.method, .post)
        
        // Verify Keychain storage
        let savedAccess = try mockKeychain.retrieve(key: "access_token")
        let savedRefresh = try mockKeychain.retrieve(key: "refresh_token")
        let savedUser = try mockKeychain.retrieve(key: "user_identifier")
        
        XCTAssertEqual(savedAccess, "credentials-access-token".data(using: .utf8))
        XCTAssertEqual(savedRefresh, "credentials-refresh-token".data(using: .utf8))
        XCTAssertEqual(savedUser, "credentials-user-id".data(using: .utf8))
    }
    
    func testCredentialsLoginFailure() async throws {
        mockAPIClient.result = .failure(NetworkError.badResponse(statusCode: 401))
        
        var states: [AuthState] = []
        authService.authStatePublisher
            .sink { states.append($0) }
            .store(in: &cancellables)
        
        let credentials = Credentials(email: "test@example.com", password: "wrong-password")
        do {
            try await authService.login(credentials: credentials)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
        
        if case .error = authService.authState {
            // Success
        } else {
            XCTFail("Expected .error authState, got \(authService.authState)")
        }
    }
    
    func testCredentialsRegisterSuccess() async throws {
        let expectedResponse = AuthResponse(
            accessToken: "registered-access-token",
            refreshToken: "registered-refresh-token",
            userIdentifier: "registered-user-id"
        )
        mockAPIClient.result = .success(expectedResponse)
        
        var states: [AuthState] = []
        authService.authStatePublisher
            .sink { states.append($0) }
            .store(in: &cancellables)
        
        let credentials = Credentials(email: "new@example.com", password: "new-password")
        try await authService.register(credentials: credentials)
        
        XCTAssertEqual(authService.authState, .authenticated)
        XCTAssertEqual(states, [.unauthenticated, .authenticating, .authenticated])
        
        // Verify route
        XCTAssertEqual(mockAPIClient.lastRoute?.path, "auth/register")
        XCTAssertEqual(mockAPIClient.lastRoute?.method, .post)
        
        // Verify Keychain storage
        let savedAccess = try mockKeychain.retrieve(key: "access_token")
        let savedRefresh = try mockKeychain.retrieve(key: "refresh_token")
        let savedUser = try mockKeychain.retrieve(key: "user_identifier")
        
        XCTAssertEqual(savedAccess, "registered-access-token".data(using: .utf8))
        XCTAssertEqual(savedRefresh, "registered-refresh-token".data(using: .utf8))
        XCTAssertEqual(savedUser, "registered-user-id".data(using: .utf8))
    }
    
    func testCredentialsRegisterFailure() async throws {
        mockAPIClient.result = .failure(NetworkError.badResponse(statusCode: 400))
        
        var states: [AuthState] = []
        authService.authStatePublisher
            .sink { states.append($0) }
            .store(in: &cancellables)
        
        let credentials = Credentials(email: "invalid-email", password: "pw")
        do {
            try await authService.register(credentials: credentials)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
        
        if case .error = authService.authState {
            // Success
        } else {
            XCTFail("Expected .error authState, got \(authService.authState)")
        }
    }
}

// MARK: - Mocks

private final class AuthServiceMockAPIClient: NetworkClientProtocol {
    var result: Result<Any, Error>?
    var lastRoute: APIRoute?
    
    func request<T: Decodable>(_ route: APIRoute) async throws -> T {
        lastRoute = route
        guard let result = result else {
            throw NetworkError.requestFailed(NSError(domain: "test", code: -1))
        }
        switch result {
        case .success(let value):
            if let decoded = value as? T {
                return decoded
            }
            throw NetworkError.decodingError(NSError(domain: "test", code: -2))
        case .failure(let error):
            throw error
        }
    }
}

private final class AuthServiceMockKeychainManager: KeychainManagerProtocol {
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
