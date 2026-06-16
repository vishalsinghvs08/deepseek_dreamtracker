import Foundation
import Combine

public enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated
    case error(String)
}

public struct AuthResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let userIdentifier: String
    
    public init(accessToken: String, refreshToken: String, userIdentifier: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userIdentifier = userIdentifier
    }
}

@MainActor
public protocol AuthServiceProtocol: AnyObject {
    var authState: AuthState { get }
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }
    func loginWithApple(identityToken: String, authorizationCode: String) async throws
    func login(credentials: Credentials) async throws
    func register(credentials: Credentials) async throws
    func logout() throws
}

public struct Credentials: Codable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

@MainActor
public final class AuthService: ObservableObject, AuthServiceProtocol {
    @Published public private(set) var authState: AuthState = .unauthenticated
    
    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }
    
    private let apiClient: NetworkClientProtocol
    private let keychain: KeychainManagerProtocol
    
    public init(
        apiClient: NetworkClientProtocol,
        keychain: KeychainManagerProtocol
    ) {
        self.apiClient = apiClient
        self.keychain = keychain
        
        // Restore session if tokens exist
        if (try? keychain.retrieve(key: "access_token")) != nil {
            self.authState = .authenticated
        }
    }
    
    public func loginWithApple(identityToken: String, authorizationCode: String) async throws {
        self.authState = .authenticating
        
        let bodyDict = [
            "identityToken": identityToken,
            "authorizationCode": authorizationCode
        ]
        
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: bodyDict)
            let endpoint = Endpoint(
                path: "auth/apple",
                method: .post,
                body: bodyData,
                requiresAuth: false,
                requiresAppAttest: false
            )
            
            let response: AuthResponse = try await apiClient.request(endpoint)
            
            // Store tokens in Keychain — guard against non-UTF8 (CRITICAL-1 fix)
            guard let accessData = response.accessToken.data(using: .utf8),
                  let refreshData = response.refreshToken.data(using: .utf8),
                  let identifierData = response.userIdentifier.data(using: .utf8) else {
                throw NetworkError.badResponse(statusCode: -1)
            }
            try keychain.save(key: "access_token", data: accessData)
            try keychain.save(key: "refresh_token", data: refreshData)
            try keychain.save(key: "user_identifier", data: identifierData)
            
            self.authState = .authenticated
        } catch {
            self.authState = .error(error.localizedDescription)
            throw error
        }
    }
    
    public func login(credentials: Credentials) async throws {
        self.authState = .authenticating
        
        do {
            let bodyData = try JSONEncoder().encode(credentials)
            let endpoint = Endpoint(
                path: "auth/login",
                method: .post,
                body: bodyData,
                requiresAuth: false,
                requiresAppAttest: false
            )
            
            let response: AuthResponse = try await apiClient.request(endpoint)
            
            guard let accessData = response.accessToken.data(using: .utf8),
                  let refreshData = response.refreshToken.data(using: .utf8),
                  let identifierData = response.userIdentifier.data(using: .utf8) else {
                throw NetworkError.badResponse(statusCode: -1)
            }
            try keychain.save(key: "access_token", data: accessData)
            try keychain.save(key: "refresh_token", data: refreshData)
            try keychain.save(key: "user_identifier", data: identifierData)
            
            self.authState = .authenticated
        } catch {
            self.authState = .error(error.localizedDescription)
            throw error
        }
    }
    
    public func register(credentials: Credentials) async throws {
        self.authState = .authenticating
        
        do {
            let bodyData = try JSONEncoder().encode(credentials)
            let endpoint = Endpoint(
                path: "auth/register",
                method: .post,
                body: bodyData,
                requiresAuth: false,
                requiresAppAttest: false
            )
            
            let response: AuthResponse = try await apiClient.request(endpoint)
            
            // Store tokens in Keychain — guard against non-UTF8 (CRITICAL-1 fix)
            guard let accessData = response.accessToken.data(using: .utf8),
                  let refreshData = response.refreshToken.data(using: .utf8),
                  let identifierData = response.userIdentifier.data(using: .utf8) else {
                throw NetworkError.badResponse(statusCode: -1)
            }
            try keychain.save(key: "access_token", data: accessData)
            try keychain.save(key: "refresh_token", data: refreshData)
            try keychain.save(key: "user_identifier", data: identifierData)
            
            self.authState = .authenticated
        } catch {
            self.authState = .error(error.localizedDescription)
            throw error
        }
    }
    
    public func logout() throws {
        try keychain.delete(key: "access_token")
        try keychain.delete(key: "refresh_token")
        try keychain.delete(key: "user_identifier")
        self.authState = .unauthenticated
    }
}
