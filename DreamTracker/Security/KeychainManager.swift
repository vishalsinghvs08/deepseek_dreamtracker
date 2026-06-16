import Foundation
import Security

public protocol KeychainManagerProtocol {
    func save(key: String, data: Data) throws
    func retrieve(key: String) throws -> Data?
    func delete(key: String) throws
}

public final class KeychainManager: KeychainManagerProtocol {
    private let service: String
    public let requireAuthentication: Bool
    
    public init(service: String = Secrets.keychainService, requireAuthentication: Bool = true) {
        self.service = service
        self.requireAuthentication = requireAuthentication
    }
    
    private func baseQuery(forKey key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
    
    public func save(key: String, data: Data) throws {
        // First delete any existing item for this key to prevent duplicates
        try? delete(key: key)
        
        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data
        
        if requireAuthentication {
            var error: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .userPresence,
                &error
            ) else {
                if let err = error?.takeRetainedValue() {
                    throw err
                }
                throw SecurityError.keychainError(status: errSecParam)
            }
            query[kSecAttrAccessControl as String] = accessControl
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keychainError(status: status)
        }
    }
    
    public func retrieve(key: String) throws -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw SecurityError.keychainError(status: status)
        }
        
        guard let data = result as? Data else {
            throw SecurityError.unexpectedData
        }
        
        return data
    }
    
    public func delete(key: String) throws {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keychainError(status: status)
        }
    }
}
