import SwiftUI
import Combine

class UsageViewModel: ObservableObject {
    @Published var usageData: UsageData?
    @Published var lastUpdated: Date?
    @Published var errorState: ErrorState?
    @Published var refreshRequested = false
    @Published var settingsRequested = false

    enum ErrorState {
        case authExpired
        case networkError
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

    /// Returns the reset time for whichever limit has the highest utilization.
    var highestResetDate: Date? {
        guard let data = usageData else { return nil }
        var bestUtil = data.fiveHour.utilization
        var bestReset = data.fiveHour.resetsAt

        let optionals: [UsageLimit?] = [
            data.sevenDaySonnet, data.sevenDayOpus,
            data.sevenDayOauthApps, data.sevenDayCowork,
            data.iguanaNecktie, data.extraUsage
        ]
        let allLimits: [UsageLimit] = [data.sevenDay] + optionals.compactMap { $0 }

        for limit in allLimits {
            if limit.utilization > bestUtil {
                bestUtil = limit.utilization
                bestReset = limit.resetsAt
            }
        }
        return bestReset
    }

    /// Formats the reset time for display in the menu bar.
    /// Shows just time if today, includes day name if different day.
    var resetTimeString: String {
        guard let resetDate = highestResetDate else { return "" }
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(resetDate, inSameDayAs: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: resetDate)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE h:mm a"
            return formatter.string(from: resetDate)
        }
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
}
