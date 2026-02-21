import Foundation
import Combine

class AccountStore: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var activeAccountId: UUID?

    private let accountsKey = "claude_accounts_metadata"
    private let activeAccountKey = "claude_active_account_id"

    var activeAccount: Account? {
        guard let id = activeAccountId else { return nil }
        return accounts.first { $0.id == id }
    }

    init() {
        loadAccounts()
        migrateIfNeeded()
    }

    // MARK: - CRUD

    func add(email: String) -> Account {
        let account = Account(email: email)
        accounts.append(account)
        if activeAccountId == nil {
            activeAccountId = account.id
        }
        saveAccounts()
        return account
    }

    func remove(id: UUID) {
        // Delete keychain credentials for this account
        KeychainService.delete(key: .sessionKey, accountId: id)
        KeychainService.delete(key: .orgId, accountId: id)

        accounts.removeAll { $0.id == id }

        // If we removed the active account, switch to the first available
        if activeAccountId == id {
            activeAccountId = accounts.first?.id
        }
        saveAccounts()
    }

    func setActive(id: UUID) {
        guard accounts.contains(where: { $0.id == id }) else { return }
        UserDefaults.standard.set(id.uuidString, forKey: activeAccountKey)
        // Set @Published property last so subscribers see the updated UserDefaults
        activeAccountId = id
    }

    func rename(id: UUID, to newName: String) {
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        accounts[index].email = newName
        saveAccounts()
    }

    func update(_ account: Account) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index] = account
        saveAccounts()
    }

    /// Save session key for an account into Keychain and update the in-memory model.
    func saveSessionKey(_ key: String, for accountId: UUID) {
        KeychainService.save(key: .sessionKey, accountId: accountId, value: key)
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].sessionKey = key
        }
        saveAccounts()
    }

    /// Save org ID for an account and update the in-memory model.
    func saveOrgId(_ orgId: String, for accountId: UUID) {
        KeychainService.save(key: .orgId, accountId: accountId, value: orgId)
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].orgId = orgId
        }
        saveAccounts()
    }

    /// Read session key for an account from Keychain (or in-memory model).
    func sessionKey(for accountId: UUID) -> String? {
        if let account = accounts.first(where: { $0.id == accountId }), let key = account.sessionKey, !key.isEmpty {
            return key
        }
        return KeychainService.read(key: .sessionKey, accountId: accountId)
    }

    /// Read org ID for an account.
    func orgId(for accountId: UUID) -> String? {
        if let account = accounts.first(where: { $0.id == accountId }), let org = account.orgId, !org.isEmpty {
            return org
        }
        return KeychainService.read(key: .orgId, accountId: accountId)
    }

    // MARK: - Persistence

    private func saveAccounts() {
        // Save metadata (id, email, orgId) to UserDefaults — session keys stay in Keychain only
        let metadata = accounts.map { AccountMetadata(id: $0.id, email: $0.email, orgId: $0.orgId) }
        if let data = try? JSONEncoder().encode(metadata) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
        if let activeId = activeAccountId {
            UserDefaults.standard.set(activeId.uuidString, forKey: activeAccountKey)
        }
    }

    private func loadAccounts() {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              let metadata = try? JSONDecoder().decode([AccountMetadata].self, from: data) else {
            return
        }

        accounts = metadata.map { meta in
            let sessionKey = KeychainService.read(key: .sessionKey, accountId: meta.id)
            return Account(id: meta.id, email: meta.email, sessionKey: sessionKey, orgId: meta.orgId)
        }

        if let activeIdString = UserDefaults.standard.string(forKey: activeAccountKey),
           let activeId = UUID(uuidString: activeIdString),
           accounts.contains(where: { $0.id == activeId }) {
            activeAccountId = activeId
        } else {
            activeAccountId = accounts.first?.id
        }
    }

    // MARK: - Migration from single-account

    private func migrateIfNeeded() {
        // Only migrate if no accounts exist yet and old credentials are present
        guard accounts.isEmpty else { return }

        let oldSessionKey = KeychainService.read(key: .sessionKey)
        let oldOrgId = KeychainService.read(key: .orgId)

        guard oldSessionKey != nil || oldOrgId != nil else { return }

        // Create a default account with migrated credentials
        var account = Account(email: "Account 1")
        account.sessionKey = oldSessionKey
        account.orgId = oldOrgId

        // Save credentials to new account-scoped keychain
        if let key = oldSessionKey {
            KeychainService.save(key: .sessionKey, accountId: account.id, value: key)
        }
        if let org = oldOrgId {
            KeychainService.save(key: .orgId, accountId: account.id, value: org)
        }

        accounts = [account]
        activeAccountId = account.id
        saveAccounts()

        // Delete old single-account keys
        KeychainService.delete(key: .sessionKey)
        KeychainService.delete(key: .orgId)
    }
}

/// Lightweight struct for persisting account metadata (no secrets).
private struct AccountMetadata: Codable {
    let id: UUID
    let email: String
    let orgId: String?
}
