import Foundation
import Security

public enum SecurityError: Error, LocalizedError, Equatable {
    case keychainError(status: OSStatus)
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case biometryNotAvailable(reason: String)
    case biometryNotEnrolled
    case passcodeNotSet
    case authenticationFailed(reason: String)
    case userCanceled
    case encryptionFailed
    case decryptionFailed
    
    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            if #available(iOS 11.3, tvOS 11.3, watchOS 4.3, macOS 10.13, *) {
                return "Keychain error: \(SecCopyErrorMessageString(status, nil) as String? ?? String(status))"
            } else {
                return "Keychain error with status code: \(status)"
            }
        case .itemNotFound:
            return "The requested item was not found in the Keychain."
        case .duplicateItem:
            return "An item with this key already exists in the Keychain."
        case .unexpectedData:
            return "The data retrieved from the Keychain was not in the expected format."
        case .biometryNotAvailable(let reason):
            return "Biometric authentication is not available: \(reason)."
        case .biometryNotEnrolled:
            return "No biometric identities (Face ID / Touch ID) are enrolled on this device."
        case .passcodeNotSet:
            return "A device passcode is not set. A passcode is required to enable security features."
        case .authenticationFailed(let reason):
            return "Biometric authentication failed: \(reason)."
        case .userCanceled:
            return "The biometric authentication prompt was canceled by the user."
        case .encryptionFailed:
            return "Encryption failed to protect the sensitive dream payload."
        case .decryptionFailed:
            return "Decryption failed. The payload might be corrupted or the key is invalid."
        }
    }
}
