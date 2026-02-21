import Foundation

struct Account: Identifiable, Codable, Equatable {
    let id: UUID
    var email: String
    var sessionKey: String?
    var orgId: String?

    var isConfigured: Bool {
        guard let key = sessionKey, let org = orgId else { return false }
        return !key.isEmpty && !org.isEmpty
    }

    init(id: UUID = UUID(), email: String, sessionKey: String? = nil, orgId: String? = nil) {
        self.id = id
        self.email = email
        self.sessionKey = sessionKey
        self.orgId = orgId
    }
}
