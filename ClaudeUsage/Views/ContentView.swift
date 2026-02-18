import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var accountStore: AccountStore

    var body: some View {
        usageContent
    }

    private func openSettings() {
        let settingsView = SettingsView(viewModel: viewModel, accountStore: accountStore)
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Claude Usage Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 360, height: 420))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var usageContent: some View {
        VStack(spacing: 0) {
            if viewModel.errorState == .authExpired {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                    Text("Session Expired")
                        .font(.headline)
                    Text("Your session key has expired. Please update it in settings.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Open Settings") {
                        openSettings()
                    }
                }
                .padding()
            } else if viewModel.usageData != nil {
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
                    if viewModel.errorState == .networkError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text("Network error")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    } else {
                        Text("Updated \(viewModel.lastUpdatedString)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.fetchNow()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        openSettings()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
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
                    Button("Open Settings") {
                        openSettings()
                    }
                }
                .padding()
            }
        }
        .frame(width: 280)
    }
}
