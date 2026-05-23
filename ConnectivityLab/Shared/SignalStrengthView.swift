import SwiftUI

struct SignalStrengthView: View {
    let rssi: Int   // dBm, typically -30 to -100

    private var dots: Int {
        switch rssi {
        case ..<(-90): return 1
        case -90 ..< -80: return 2
        case -80 ..< -70: return 3
        case -70 ..< -60: return 4
        default: return 5
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(index <= dots ? Color.accentColor : Color.secondary.opacity(0.3))
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SignalStrengthView(rssi: -45)
        SignalStrengthView(rssi: -62)
        SignalStrengthView(rssi: -81)
        SignalStrengthView(rssi: -95)
    }
    .padding()
}
