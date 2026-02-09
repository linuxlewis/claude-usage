import Foundation

enum UsageServiceError: Error, Equatable {
    case authError(statusCode: Int)
    case httpError(statusCode: Int)
    case missingCredentials
    case invalidResponse
}

struct UsageService {
    private let session: URLSession
    private let sessionKey: String
    private let orgId: String

    static let baseURL = "https://claude.ai/api/organizations"

    init(sessionKey: String, orgId: String, session: URLSession = .shared) {
        self.sessionKey = sessionKey
        self.orgId = orgId
        self.session = session
    }

    func fetchUsage() async throws -> (UsageData, newSessionKey: String?) {
        let url = URL(string: "\(Self.baseURL)/\(orgId)/usage")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("*/*", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("web_claude_ai", forHTTPHeaderField: "anthropic-client-platform")
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw UsageServiceError.authError(statusCode: httpResponse.statusCode)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw UsageServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            let basic = ISO8601DateFormatter()
            basic.formatOptions = [.withInternetDateTime]
            if let date = basic.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        let usageData = try decoder.decode(UsageData.self, from: data)

        let newSessionKey = Self.parseSetCookieSessionKey(from: httpResponse)

        return (usageData, newSessionKey: newSessionKey)
    }

    static func parseSetCookieSessionKey(from response: HTTPURLResponse) -> String? {
        guard let setCookieHeaders = response.allHeaderFields["Set-Cookie"] as? String else {
            return nil
        }

        for part in setCookieHeaders.components(separatedBy: ";") {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("sessionKey=") {
                return String(trimmed.dropFirst("sessionKey=".count))
            }
        }

        return nil
    }
}
