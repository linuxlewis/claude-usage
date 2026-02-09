import SwiftUI
import Combine

class UsageViewModel: ObservableObject {
    @Published var usageData: UsageData?
    @Published var lastUpdated: Date?
    @Published var errorState: ErrorState?

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
}
