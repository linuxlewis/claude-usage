import SwiftUI

@main
struct ClaudeUsageApp: App {
    var body: some Scene {
        MenuBarExtra("Claude Usage", systemImage: "chart.pie") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
