import SwiftUI

enum Transport {
    case ble, wifi
}

struct ContentView: View {
    @State private var selected: Transport = .ble
    @State private var bleManager = BLEManager()
    @State private var wifiPinger = WiFiPinger()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Transport", selection: $selected) {
                    Text("BLE").tag(Transport.ble)
                    Text("Wi-Fi").tag(Transport.wifi)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                switch selected {
                case .ble:
                    BLEListView(manager: bleManager)
                case .wifi:
                    WiFiStatusView(pinger: wifiPinger)
                }

                Spacer()
            }
            .navigationTitle("ConnectivityLab")
        }
    }
}
