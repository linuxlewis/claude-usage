import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var accountStore: AccountStore
    @State private var showingAddAccount = false
    @State private var newAccountEmail = ""

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

    private var accountPicker: some View {
        Group {
            if accountStore.accounts.count >= 2 {
                Picker("Account", selection: Binding(
                    get: { accountStore.activeAccountId ?? UUID() },
                    set: { accountStore.setActive(id: $0) }
                )) {
                    ForEach(accountStore.accounts) { account in
                        Text(account.email).tag(account.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
            }
        }
    }

    private var toolbarButtons: some View {
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
                showingAddAccount = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingAddAccount) {
                addAccountPopover
            }

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
    }

    private var addAccountPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Account")
                .font(.headline)

            TextField("Email or label", text: $newAccountEmail)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))

            HStack {
                Spacer()
                Button("Cancel") {
                    newAccountEmail = ""
                    showingAddAccount = false
                }
                Button("Add") {
                    let account = accountStore.add(email: newAccountEmail)
                    accountStore.setActive(id: account.id)
                    newAccountEmail = ""
                    showingAddAccount = false
                }
                .disabled(newAccountEmail.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 240)
    }

    private var usageContent: some View {
        VStack(spacing: 0) {
            accountPicker

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

                toolbarButtons
            } else if viewModel.authStatus == .connected {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading usage data…")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding()
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
