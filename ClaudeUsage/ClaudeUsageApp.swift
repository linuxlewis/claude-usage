import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                if viewModel.errorState == .authExpired {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                } else if viewModel.errorState == .networkError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                } else {
                    CircleProgress(percentage: viewModel.highestUtilization, size: 16)
                }
                if !viewModel.resetTimeString.isEmpty {
                    Text(viewModel.resetTimeString)
                        .font(.system(size: 11))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
