import Foundation
import LocalAuthentication

public protocol LAContextProtocol {
    var biometryType: LABiometryType { get }
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool
}

extension LAContext: LAContextProtocol {}

public protocol BiometricAuthenticating {
    func canEvaluateBiometrics() -> Bool
    func evaluateBiometrics(reason: String) async throws -> Bool
    var biometricType: LABiometryType { get }
}

public final class BiometricAuthenticator: BiometricAuthenticating {
    private let contextFactory: () -> LAContextProtocol
    
    public init(contextFactory: @escaping () -> LAContextProtocol = { LAContext() }) {
        self.contextFactory = contextFactory
    }
    
    public var biometricType: LABiometryType {
        let context = contextFactory()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }
    
    public func canEvaluateBiometrics() -> Bool {
        let context = contextFactory()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public func evaluateBiometrics(reason: String) async throws -> Bool {
        let context = contextFactory()
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let err = error {
                let code = LAError.Code(rawValue: err.code) ?? .biometryNotAvailable
                throw mapLAErrorCode(code, description: err.localizedDescription)
            }
            throw SecurityError.biometryNotAvailable(reason: "Unknown error")
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let laError as LAError {
            throw mapLAErrorCode(laError.code, description: laError.localizedDescription)
        } catch {
            throw SecurityError.authenticationFailed(reason: error.localizedDescription)
        }
    }
    
    private func mapLAErrorCode(_ code: LAError.Code, description: String) -> SecurityError {
        switch code {
        case .biometryNotAvailable:
            return .biometryNotAvailable(reason: description)
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .passcodeNotSet:
            return .passcodeNotSet
        case .authenticationFailed:
            return .authenticationFailed(reason: description)
        case .userCancel:
            return .userCanceled
        default:
            return .authenticationFailed(reason: description)
        }
    }
}
