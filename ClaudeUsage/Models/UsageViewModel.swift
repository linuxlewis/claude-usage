import SwiftUI
import Combine

enum TimeDisplayFormat: String, CaseIterable {
    case resetTime = "reset_time"
    case remainingTime = "remaining_time"
    
    var displayName: String {
        switch self {
        case .resetTime:
            return "Reset Time"
        case .remainingTime:
            return "Time Until Reset"
        }
    }
}

class UsageViewModel: ObservableObject {
    @Published var usageData: UsageData?
    @Published var lastUpdated: Date?
    @Published var errorState: ErrorState?
    @Published var refreshRequested = false
    @Published var authStatus: AuthStatus = .notConfigured
    @Published var timeDisplayFormat = TimeDisplayFormat.resetTime

    enum ErrorState: Equatable {
        case authExpired
        case networkError
    }

    enum AuthStatus {
        case connected
        case expired
        case notConfigured
    }

    private let pollingInterval: TimeInterval = 300 // 5 minutes
    private var pollingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initialize time display preference from UserDefaults
        let savedFormat = UserDefaults.standard.string(forKey: "claude_time_display_format") ?? TimeDisplayFormat.resetTime.rawValue
        timeDisplayFormat = TimeDisplayFormat(rawValue: savedFormat) ?? .resetTime

        updateAuthStatus()

        // Watch for refresh requests
        $refreshRequested
            .filter { $0 }
            .sink { [weak self] _ in
                self?.refreshRequested = false
                self?.fetchNow()
            }
            .store(in: &cancellables)

        // Watch for UserDefaults changes to update timeDisplayFormat
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    let savedFormat = UserDefaults.standard.string(forKey: "claude_time_display_format") ?? TimeDisplayFormat.resetTime.rawValue
                    self?.timeDisplayFormat = TimeDisplayFormat(rawValue: savedFormat) ?? .resetTime
                }
            }
            .store(in: &cancellables)

        // Start polling if credentials exist
        startPollingIfConfigured()
    }

    deinit {
        pollingTask?.cancel()
    }

    func updateAuthStatus() {
        let hasKey = KeychainService.read(key: .sessionKey) != nil
        let hasOrg = KeychainService.read(key: .orgId) != nil
        if hasKey && hasOrg {
            if errorState == .authExpired {
                authStatus = .expired
            } else if usageData != nil {
                authStatus = .connected
            } else {
                // Credentials exist but haven't verified yet
                authStatus = .notConfigured
            }
        } else {
            authStatus = .notConfigured
        }
    }

    /// Starts polling if credentials are available. Call after saving new credentials.
    func startPollingIfConfigured() {
        pollingTask?.cancel()

        guard let sessionKey = KeychainService.read(key: .sessionKey),
              let orgId = KeychainService.read(key: .orgId),
              !sessionKey.isEmpty, !orgId.isEmpty else {
            return
        }

        pollingTask = Task { [weak self] in
            guard let self = self else { return }
            // Initial fetch
            await self.performFetch(sessionKey: sessionKey, orgId: orgId)

            // Polling loop
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.pollingInterval * 1_000_000_000))
                if Task.isCancelled { break }
                // Re-read credentials in case they were updated
                guard let currentKey = KeychainService.read(key: .sessionKey),
                      let currentOrg = KeychainService.read(key: .orgId) else {
                    break
                }
                await self.performFetch(sessionKey: currentKey, orgId: currentOrg)
            }
        }
    }

    /// Triggers an immediate fetch outside the polling cycle.
    func fetchNow() {
        guard let sessionKey = KeychainService.read(key: .sessionKey),
              let orgId = KeychainService.read(key: .orgId),
              !sessionKey.isEmpty, !orgId.isEmpty else {
            return
        }

        Task { [weak self] in
            await self?.performFetch(sessionKey: sessionKey, orgId: orgId)
        }
    }

    @MainActor
    private func performFetch(sessionKey: String, orgId: String) async {
        let service = UsageService(sessionKey: sessionKey, orgId: orgId)
        do {
            let (data, newKey) = try await service.fetchUsage()

            // Update Keychain if a new session key was returned via Set-Cookie
            if let newKey = newKey {
                KeychainService.save(key: .sessionKey, value: newKey)
            }

            usageData = data
            lastUpdated = Date()
            errorState = nil
            authStatus = .connected
        } catch let error as UsageServiceError {
            switch error {
            case .authError:
                errorState = .authExpired
                authStatus = .expired
            default:
                errorState = .networkError
            }
        } catch {
            errorState = .networkError
        }
    }

    /// Returns the highest utilization percentage across all non-nil limits.
    var highestUtilization: Double {
        guard let data = usageData else { return 0 }
        var limits: [UsageLimit] = [data.fiveHour, data.sevenDay]
        if let s = data.sevenDaySonnet { limits.append(s) }
        if let o = data.sevenDayOpus { limits.append(o) }
        if let oa = data.sevenDayOauthApps { limits.append(oa) }
        if let c = data.sevenDayCowork { limits.append(c) }
        if let i = data.iguanaNecktie { limits.append(i) }
        if let e = data.extraUsage { limits.append(e) }
        return limits.map(\.utilization).max() ?? 0
    }

    /// Returns a human-readable string for how long ago data was last updated.
    var lastUpdatedString: String {
        guard let lastUpdated = lastUpdated else { return "Never" }
        let seconds = Int(Date().timeIntervalSince(lastUpdated))
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else {
            let hours = seconds / 3600
            return "\(hours)h ago"
        }
    }

    /// Collects all non-nil limits with display names for use in the popover.
    var displayLimits: [(name: String, limit: UsageLimit)] {
        guard let data = usageData else { return [] }
        var results: [(name: String, limit: UsageLimit)] = [
            ("Session", data.fiveHour),
            ("Weekly", data.sevenDay),
        ]
        if let s = data.sevenDaySonnet { results.append(("Sonnet", s)) }
        if let o = data.sevenDayOpus { results.append(("Opus", o)) }
        if let oa = data.sevenDayOauthApps { results.append(("OAuth Apps", oa)) }
        if let c = data.sevenDayCowork { results.append(("Cowork", c)) }
        if let i = data.iguanaNecktie { results.append(("Other", i)) }
        if let e = data.extraUsage { results.append(("Extra Usage", e)) }
        return results
    }

    /// Returns a formatted string showing time remaining until the 5-hour limit resets.
    var remainingTimeString: String {
        guard let resetDate = usageData?.fiveHour.resetsAt else { return "" }

        let now = Date()
        let timeInterval = resetDate.timeIntervalSince(now)

        // If reset time is in the past, show "Now" or similar
        if timeInterval <= 0 {
            return "Now"
        }

        let totalMinutes = Int(timeInterval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }

    /// Returns the formatted reset time string (existing behavior).
    var resetTimeString: String {
        guard let resetDate = usageData?.fiveHour.resetsAt else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: resetDate)
    }

    /// Returns the appropriate time string based on user preference.
    var menuBarTimeString: String {
        switch timeDisplayFormat {
        case .resetTime:
            return resetTimeString
        case .remainingTime:
            return remainingTimeString
        }
    }
}
