import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var viewModel = UsageViewModel()
    private var menuBarText: String {
        let pct = Int(viewModel.highestUtilization)
        let resetDate: Date? = viewModel.usageData?.fiveHour.resetsAt ?? viewModel.usageData?.sevenDay.resetsAt
        if let date = resetDate {
            let fmt = DateFormatter()
            fmt.dateFormat = "h:mm a"
            return "\(pct)% · \(fmt.string(from: date))"
        }
        return "\(pct)%"
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            HStack(spacing: 3) {
                Image("MenuBarIcon")
                    .renderingMode(.template)
                Text(menuBarText)
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
