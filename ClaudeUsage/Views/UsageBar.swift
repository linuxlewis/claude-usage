import SwiftUI

struct UsageBar: View {
    let name: String
    let limit: UsageLimit

    private var percentage: Double {
        min(max(limit.utilization, 0), 100)
    }

    private var barColor: Color {
        if percentage >= 80 {
            return .red
        } else if percentage >= 50 {
            return .yellow
        } else {
            return .green
        }
    }

    private var resetTimeString: String {
        guard let resetDate = limit.resetsAt else { return "" }
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(resetDate, inSameDayAs: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Resets at \(formatter.string(from: resetDate))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE h:mm a"
            return "Resets \(formatter.string(from: resetDate))"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                CircleProgress(percentage: percentage, size: 20)
                Text("\(Int(percentage))%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 6)
                }
            }
            .frame(height: 6)

            if !resetTimeString.isEmpty {
                Text(resetTimeString)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}
