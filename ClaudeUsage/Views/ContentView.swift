import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.usageData != nil {
                VStack(spacing: 16) {
                    ForEach(Array(viewModel.displayLimits.enumerated()), id: \.offset) { _, item in
                        UsageBar(name: item.name, limit: item.limit)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()

                HStack {
                    Text("Updated \(viewModel.lastUpdatedString)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        viewModel.refreshRequested = true
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        viewModel.settingsRequested = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    Text("Claude Usage")
                        .font(.headline)
                    Text("Not configured")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .frame(width: 280)
    }
}
