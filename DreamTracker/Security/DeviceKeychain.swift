import Foundation
import Security
import CryptoKit

// MARK: - Device Keychain

/// Generates and stores a device-specific symmetric key in the Keychain.
/// Used to encrypt/decrypt local data so even if the JSON file is extracted,
/// it cannot be read without the device's Keychain key.
final class DeviceKeychain {
    private static let keyTag = "com.dreamtracker.devicekey".data(using: .utf8)!

    /// Retrieves or creates a 256-bit symmetric key stored in the Keychain.
    static func getOrCreateKey() throws -> SymmetricKey {
        if let existing = try? loadKey() {
            return existing
        }
        return try createAndStoreKey()
    }

    private static func loadKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return SymmetricKey(data: data)
    }

    private static func createAndStoreKey() throws -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }

        // Delete any existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Store new key
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "DeviceKeychain", code: Int(status))
        }

        return key
    }
}
