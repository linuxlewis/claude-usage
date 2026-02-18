import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var accountStore = AccountStore()
    @StateObject private var viewModel: UsageViewModel

    init() {
        let store = AccountStore()
        _accountStore = StateObject(wrappedValue: store)
        _viewModel = StateObject(wrappedValue: UsageViewModel(accountStore: store))
    }

    private var menuBarText: String {
        let pct = Int(viewModel.usageData?.fiveHour.utilization ?? 0)
        let resetDate: Date? = viewModel.usageData?.fiveHour.resetsAt
        if let date = resetDate {
            let timeText = viewModel.menuBarTimeString
            return "\(pct)% · \(timeText)"
        }
        return "\(pct)%"
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel, accountStore: accountStore)
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
