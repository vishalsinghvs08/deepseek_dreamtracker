import Foundation
import DeviceCheck

public protocol AppAttestManagerProtocol {
    var isSupported: Bool { get }
    func generateKey() async throws -> String
    func attestKey(keyId: String, clientDataHash: Data) async throws -> Data
    func generateAssertion(keyId: String, clientDataHash: Data) async throws -> Data
}

public final class AppAttestManager: AppAttestManagerProtocol {
    private let attestService: DCAppAttestService
    
    public init(attestService: DCAppAttestService = .shared) {
        self.attestService = attestService
    }
    
    public var isSupported: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return attestService.isSupported
        #endif
    }
    
    public func generateKey() async throws -> String {
        guard isSupported else {
            throw AppAttestError.notSupported
        }
        return try await attestService.generateKey()
    }
    
    public func attestKey(keyId: String, clientDataHash: Data) async throws -> Data {
        guard isSupported else {
            throw AppAttestError.notSupported
        }
        return try await attestService.attestKey(keyId, clientDataHash: clientDataHash)
    }
    
    public func generateAssertion(keyId: String, clientDataHash: Data) async throws -> Data {
        guard isSupported else {
            throw AppAttestError.notSupported
        }
        return try await attestService.generateAssertion(keyId, clientDataHash: clientDataHash)
    }
}

public enum AppAttestError: Error, LocalizedError {
    case notSupported
    
    public var errorDescription: String? {
        switch self {
        case .notSupported:
            return "DCAppAttestService is not supported on this device/environment."
        }
    }
}
