import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                CircleProgress(percentage: viewModel.highestUtilization, size: 16)
                if !viewModel.resetTimeString.isEmpty {
                    Text(viewModel.resetTimeString)
                        .font(.system(size: 11))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
