import Foundation
import CryptoKit

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct Endpoint: APIRoute {
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]?
    public let body: Data?
    public let requiresAuth: Bool
    public let requiresAppAttest: Bool
    
    public init(
        path: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Data? = nil,
        requiresAuth: Bool = true,
        requiresAppAttest: Bool = false
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
        self.requiresAuth = requiresAuth
        self.requiresAppAttest = requiresAppAttest
    }
}

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case badResponse(statusCode: Int)
    case unauthorized
    case decodingError(Error)
    case requestFailed(Error)
    case appAttestUnsupported
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .badResponse(let statusCode):
            return "The server responded with an error status code: \(statusCode)."
        case .unauthorized:
            return "The request was unauthorized."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .appAttestUnsupported:
            return "App Attest is not supported on this device/environment."
        }
    }
}

public struct TokenRefreshResponse: Codable {
    public let accessToken: String
    public let refreshToken: String?
    
    public init(accessToken: String, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public struct ChallengeResponse: Codable {
    public let challenge: String
    
    public init(challenge: String) {
        self.challenge = challenge
    }
}

public protocol NetworkClientProtocol {
    func request<T: Decodable>(_ route: APIRoute) async throws -> T
}

public final class APIClient: NetworkClientProtocol {
    internal let session: URLSession
    private let baseURL: URL
    private let keychain: KeychainManagerProtocol
    private let appAttestManager: AppAttestManagerProtocol
    private let refreshCoordinator: TokenRefreshCoordinator
    
    public init(
        baseURL: URL = Secrets.backendURL,
        pinnedHashes: Set<String> = [],
        keychain: KeychainManagerProtocol = KeychainManager(requireAuthentication: false),
        appAttestManager: AppAttestManagerProtocol = AppAttestManager()
    ) {
        self.baseURL = baseURL
        self.keychain = keychain
        self.appAttestManager = appAttestManager
        
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv13
        if pinnedHashes.isEmpty {
            self.session = URLSession(configuration: configuration)
        } else {
            let delegate = PinnedSessionDelegate(pinnedHashes: pinnedHashes)
            self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        }
        
        self.refreshCoordinator = TokenRefreshCoordinator(keychain: keychain, baseURL: baseURL, session: self.session)
    }
    
    internal init(
        baseURL: URL,
        keychain: KeychainManagerProtocol,
        appAttestManager: AppAttestManagerProtocol,
        session: URLSession
    ) {
        self.baseURL = baseURL
        self.keychain = keychain
        self.appAttestManager = appAttestManager
        self.session = session
        self.refreshCoordinator = TokenRefreshCoordinator(keychain: keychain, baseURL: baseURL, session: session)
    }
    
    public func request<T: Decodable>(_ route: APIRoute) async throws -> T {
        let request = try await buildRequest(for: route)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.badResponse(statusCode: 0)
            }
            
            if httpResponse.statusCode == 401 && route.requiresAuth {
                // Try refresh token and retry request once
                let newAccessToken = try await refreshCoordinator.refreshToken()
                let retriedRequest = try await buildRequest(for: route, overrideAccessToken: newAccessToken)
                let (retriedData, retriedResponse) = try await session.data(for: retriedRequest)
                
                guard let httpRetriedResponse = retriedResponse as? HTTPURLResponse else {
                    throw NetworkError.badResponse(statusCode: 0)
                }
                
                guard (200...299).contains(httpRetriedResponse.statusCode) else {
                    if httpRetriedResponse.statusCode == 401 {
                        throw NetworkError.unauthorized
                    } else {
                        throw NetworkError.badResponse(statusCode: httpRetriedResponse.statusCode)
                    }
                }
                
                let finalData = retriedData.isEmpty ? "{}".data(using: .utf8)! : retriedData
                return try decode(finalData)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw NetworkError.unauthorized
                }
                throw NetworkError.badResponse(statusCode: httpResponse.statusCode)
            }
            
            let finalData = data.isEmpty ? "{}".data(using: .utf8)! : data
            return try decode(finalData)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    private func ensureAppAttestKeyRegistered() async throws -> String {
        if let keyIdData = try? keychain.retrieve(key: "app_attest_key_id"),
           let keyId = String(data: keyIdData, encoding: .utf8) {
            return keyId
        }
        
        guard appAttestManager.isSupported else {
            throw AppAttestError.notSupported
        }
        
        let keyId = try await appAttestManager.generateKey()
        
        let challengeResponse: ChallengeResponse = try await request(Endpoint(
            path: "auth/attest-challenge",
            method: .post,
            requiresAuth: true,
            requiresAppAttest: false
        ))
        
        guard let challengeData = Data(base64Encoded: challengeResponse.challenge) else {
            throw NetworkError.decodingError(NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid challenge base64"]))
        }
        let clientDataHash = Data(SHA256.hash(data: challengeData))
        
        let attestation = try await appAttestManager.attestKey(keyId: keyId, clientDataHash: clientDataHash)
        
        struct AttestRegisterBody: Codable {
            let keyId: String
            let attestation: String
            let clientDataHash: String
        }
        
        let registerBody = AttestRegisterBody(
            keyId: keyId,
            attestation: attestation.base64EncodedString(),
            clientDataHash: clientDataHash.base64EncodedString()
        )
        
        let bodyData = try JSONEncoder().encode(registerBody)
        let registerEndpoint = Endpoint(
            path: "auth/register-attestation",
            method: .post,
            body: bodyData,
            requiresAuth: true,
            requiresAppAttest: false
        )
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await request(registerEndpoint)
        
        guard let keyIdData = keyId.data(using: .utf8) else {
            throw NetworkError.badResponse(statusCode: -1)
        }
        try keychain.save(key: "app_attest_key_id", data: keyIdData)
        return keyId
    }
    
    private func buildRequest(for route: APIRoute, overrideAccessToken: String? = nil) async throws -> URLRequest {
        let url = baseURL.appendingPathComponent(route.path)
        var request = URLRequest(url: url)
        request.httpMethod = route.method.rawValue
        request.httpBody = route.body
        
        // Base headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let headers = route.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Authorization JWT Injection
        if route.requiresAuth {
            let token: String?
            if let overrideToken = overrideAccessToken {
                token = overrideToken
            } else if let tokenData = try? keychain.retrieve(key: "access_token") {
                // MEDIUM-3 fix: throw instead of silently sending no auth header
                guard let decoded = String(data: tokenData, encoding: .utf8) else {
                    throw NetworkError.unauthorized
                }
                token = decoded
            } else {
                token = nil
            }
            
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // App Attest headers
        if route.requiresAppAttest {
            guard appAttestManager.isSupported else {
                throw NetworkError.appAttestUnsupported
            }
            let keyId = try await ensureAppAttestKeyRegistered()
            
            let bodyData = route.body ?? Data()
            let method = route.method.rawValue
            let path = route.path
            let timestamp = String(Int(Date().timeIntervalSince1970))
            let nonce = UUID().uuidString
            
            struct ClientData: Codable {
                let method: String
                let path: String
                let body: Data
                let timestamp: String
                let nonce: String
            }
            
            let clientData = ClientData(method: method, path: path, body: bodyData, timestamp: timestamp, nonce: nonce)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let clientDataJSON = try encoder.encode(clientData)
            let clientDataHash = Data(SHA256.hash(data: clientDataJSON))
            
            let assertion = try await appAttestManager.generateAssertion(keyId: keyId, clientDataHash: clientDataHash)
            
            request.setValue(keyId, forHTTPHeaderField: "X-App-Attest-Key-Id")
            request.setValue(assertion.base64EncodedString(), forHTTPHeaderField: "X-App-Attest-Assertion")
            request.setValue(clientDataHash.base64EncodedString(), forHTTPHeaderField: "X-App-Attest-Client-Data")
            request.setValue(timestamp, forHTTPHeaderField: "X-App-Attest-Timestamp")
            request.setValue(nonce, forHTTPHeaderField: "X-App-Attest-Nonce")
        }
        
        return request
    }
    
    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

public actor TokenRefreshCoordinator {
    private var refreshTask: Task<String, Error>?
    private let keychain: KeychainManagerProtocol
    private let baseURL: URL
    let session: URLSession
    
    public init(keychain: KeychainManagerProtocol, baseURL: URL, session: URLSession = .shared) {
        self.keychain = keychain
        self.baseURL = baseURL
        self.session = session
    }
    
    public func refreshToken() async throws -> String {
        if let task = refreshTask {
            return try await task.value
        }
        
        let task = Task<String, Error> {
            defer {
                refreshTask = nil
            }
            
            do {
                guard let refreshTokenData = try keychain.retrieve(key: "refresh_token"),
                      let refreshToken = String(data: refreshTokenData, encoding: .utf8) else {
                    throw NetworkError.unauthorized
                }
                
                let url = baseURL.appendingPathComponent("auth/refresh")
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let bodyDict = ["refresh_token": refreshToken]
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
                
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.unauthorized
                }
                
                let refreshResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
                // CRITICAL-1 fix in TokenRefreshCoordinator: guard .utf8 encoding
                guard let newAccessData = refreshResponse.accessToken.data(using: .utf8) else {
                    throw NetworkError.badResponse(statusCode: -1)
                }
                try keychain.save(key: "access_token", data: newAccessData)
                if let newRefresh = refreshResponse.refreshToken {
                    guard let newRefreshData = newRefresh.data(using: .utf8) else {
                        throw NetworkError.badResponse(statusCode: -1)
                    }
                    try keychain.save(key: "refresh_token", data: newRefreshData)
                }
                return refreshResponse.accessToken
            } catch {
                try? keychain.delete(key: "access_token")
                try? keychain.delete(key: "refresh_token")
                throw error
            }
        }
        
        refreshTask = task
        return try await task.value
    }
}
