import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Claude Usage")
                .font(.headline)
            if viewModel.usageData != nil {
                Text("\(Int(viewModel.highestUtilization))% used")
                    .foregroundColor(.secondary)
            } else {
                Text("Not configured")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 280)
    }
}
