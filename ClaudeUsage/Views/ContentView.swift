import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Claude Usage")
                .font(.headline)
            Text("Not configured")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 280)
    }
}
