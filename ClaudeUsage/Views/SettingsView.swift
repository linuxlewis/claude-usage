import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UsageViewModel
    @State private var sessionKeyInput = ""
    @State private var orgIdInput = ""
    @State private var isTesting = false
    @State private var testResult: TestResult?

    enum TestResult {
        case success
        case authError
        case networkError(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: {
                    viewModel.settingsRequested = false
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)

                Text("Settings")
                    .font(.headline)

                Spacer()
            }

            // Auth status
            HStack(spacing: 6) {
                Circle()
                    .fill(authStatusColor)
                    .frame(width: 8, height: 8)
                Text(authStatusText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Session Key
            VStack(alignment: .leading, spacing: 4) {
                Text("Session Key")
                    .font(.system(size: 12, weight: .medium))
                SecureField("Paste sessionKey cookie value", text: $sessionKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            // Org ID
            VStack(alignment: .leading, spacing: 4) {
                Text("Organization ID")
                    .font(.system(size: 12, weight: .medium))
                TextField("Paste org ID", text: $orgIdInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            // Buttons
            HStack {
                Button("Save") {
                    saveCredentials()
                }
                .disabled(sessionKeyInput.isEmpty || orgIdInput.isEmpty)

                Button("Test Connection") {
                    testConnection()
                }
                .disabled(sessionKeyInput.isEmpty || orgIdInput.isEmpty || isTesting)

                if isTesting {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                }
            }

            // Test result
            if let result = testResult {
                HStack(spacing: 4) {
                    switch result {
                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connection successful")
                            .foregroundColor(.green)
                    case .authError:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Authentication failed — check session key")
                            .foregroundColor(.red)
                    case .networkError(let message):
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(message)
                            .foregroundColor(.orange)
                    }
                }
                .font(.system(size: 11))
            }
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            sessionKeyInput = KeychainService.read(key: .sessionKey) ?? ""
            orgIdInput = KeychainService.read(key: .orgId) ?? ""
        }
    }

    private var authStatusColor: Color {
        switch viewModel.authStatus {
        case .connected: return .green
        case .expired: return .red
        case .notConfigured: return .gray
        }
    }

    private var authStatusText: String {
        switch viewModel.authStatus {
        case .connected: return "Connected"
        case .expired: return "Session expired"
        case .notConfigured: return "Not configured"
        }
    }

    private func saveCredentials() {
        KeychainService.save(key: .sessionKey, value: sessionKeyInput)
        KeychainService.save(key: .orgId, value: orgIdInput)
        viewModel.updateAuthStatus()
        testResult = nil
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        let service = UsageService(sessionKey: sessionKeyInput, orgId: orgIdInput)

        Task {
            do {
                let (_, newKey) = try await service.fetchUsage()
                if let newKey = newKey {
                    KeychainService.save(key: .sessionKey, value: newKey)
                    await MainActor.run {
                        sessionKeyInput = newKey
                    }
                }
                await MainActor.run {
                    testResult = .success
                    isTesting = false
                    saveCredentials()
                    viewModel.authStatus = .connected
                }
            } catch let error as UsageServiceError {
                await MainActor.run {
                    switch error {
                    case .authError:
                        testResult = .authError
                        viewModel.authStatus = .expired
                    default:
                        testResult = .networkError("Request failed: \(error)")
                    }
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = .networkError("Network error: \(error.localizedDescription)")
                    isTesting = false
                }
            }
        }
    }
}
