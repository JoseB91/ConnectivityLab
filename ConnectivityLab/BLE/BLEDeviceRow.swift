import SwiftUI
import CoreBluetooth

struct BLEDeviceRow: View {
    let peripheral: CBPeripheral
    let rssi: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(peripheral.name ?? "Unknown")
                    .font(.body)
                Text(peripheral.identifier.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            SignalStrengthView(rssi: rssi)

            Text("\(rssi) dBm")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

struct BLEListView: View {
    var manager: BLEManager

    var body: some View {
        VStack {
            if let error = manager.stateError {
                ContentUnavailableView(error, systemImage: "bluetooth.slash")
                    .padding()
            } else if manager.peripherals.isEmpty && !manager.isScanning {
                ContentUnavailableView("No Devices", systemImage: "antenna.radiowaves.left.and.right.slash",
                                       description: Text("Tap Scan to discover nearby BLE devices."))
                    .padding()
            } else {
                List(manager.peripherals, id: \.peripheral.identifier) { item in
                    BLEDeviceRow(peripheral: item.peripheral, rssi: item.rssi)
                }
                .listStyle(.plain)
            }

            Spacer()

            Button(manager.isScanning ? "Stop" : "Scan") {
                manager.isScanning ? manager.stopScan() : manager.startScan()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear { manager.startScan() }
        .onDisappear { manager.stopScan() }
    }
}
