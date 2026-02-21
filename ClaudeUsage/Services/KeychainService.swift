import Foundation
import Security

struct KeychainService {
    private static let serviceName = "com.claudeusage.credentials"

    // In-memory cache to avoid repeated keychain access (which triggers password prompts)
    private static var cache: [String: String] = [:]

    enum KeychainKey: String {
        case sessionKey = "sessionKey"
        case orgId = "orgId"
    }

    @discardableResult
    static func save(key: KeychainKey, value: String) -> Bool {
        // Update cache
        cache[key.rawValue] = value

        // Org ID isn't secret — store in UserDefaults
        if key == .orgId {
            UserDefaults.standard.set(value, forKey: "claude_org_id")
            return true
        }

        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func read(key: KeychainKey) -> String? {
        // Check cache first
        if let cached = cache[key.rawValue] {
            return cached
        }

        // Org ID from UserDefaults
        if key == .orgId {
            let value = UserDefaults.standard.string(forKey: "claude_org_id")
            if let value { cache[key.rawValue] = value }
            return value
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        let value = String(data: data, encoding: .utf8)
        if let value { cache[key.rawValue] = value }
        return value
    }

    @discardableResult
    static func delete(key: KeychainKey) -> Bool {
        // Clear cache
        cache.removeValue(forKey: key.rawValue)

        if key == .orgId {
            UserDefaults.standard.removeObject(forKey: "claude_org_id")
            return true
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Multi-account scoped methods

    private static func accountKey(_ key: KeychainKey, accountId: UUID) -> String {
        "\(accountId.uuidString)-\(key.rawValue)"
    }

    @discardableResult
    static func save(key: KeychainKey, accountId: UUID, value: String) -> Bool {
        let scopedKey = accountKey(key, accountId: accountId)
        cache[scopedKey] = value

        if key == .orgId {
            UserDefaults.standard.set(value, forKey: "claude_org_id_\(accountId.uuidString)")
            return true
        }

        guard let data = value.data(using: .utf8) else { return false }

        delete(key: key, accountId: accountId)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: scopedKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func read(key: KeychainKey, accountId: UUID) -> String? {
        let scopedKey = accountKey(key, accountId: accountId)

        if let cached = cache[scopedKey] {
            return cached
        }

        if key == .orgId {
            let value = UserDefaults.standard.string(forKey: "claude_org_id_\(accountId.uuidString)")
            if let value { cache[scopedKey] = value }
            return value
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: scopedKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        let value = String(data: data, encoding: .utf8)
        if let value { cache[scopedKey] = value }
        return value
    }

    @discardableResult
    static func delete(key: KeychainKey, accountId: UUID) -> Bool {
        let scopedKey = accountKey(key, accountId: accountId)
        cache.removeValue(forKey: scopedKey)

        if key == .orgId {
            UserDefaults.standard.removeObject(forKey: "claude_org_id_\(accountId.uuidString)")
            return true
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: scopedKey,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
