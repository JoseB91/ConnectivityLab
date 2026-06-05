import SwiftUI
import CoreBluetooth

struct BLEDeviceDetailView: View {
    @Bindable var manager: BLEManager
    let peripheral: CBPeripheral

    var body: some View {
        Group {
            if manager.connectedPeripheral == peripheral {
                serviceList
            } else if manager.connectingPeripheralID == peripheral.identifier {
                connectingView
            } else {
                connectPrompt
            }
        }
        .navigationTitle(peripheral.name ?? "Unknown Device")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if manager.connectedPeripheral == peripheral {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Disconnect", role: .destructive) {
                        manager.disconnect()
                    }
                }
            }
        }
        .task {
            guard manager.connectedPeripheral != peripheral,
                  manager.connectingPeripheralID != peripheral.identifier else { return }
            do {
                try await manager.connect(peripheral: peripheral)
            } catch {
                manager.connectionError = error.localizedDescription
            }
        }
    }

    private var connectingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Connecting…")
                .foregroundStyle(.secondary)
        }
    }

    private var connectPrompt: some View {
        VStack(spacing: 16) {
            if let error = manager.connectionError {
                ContentUnavailableView(
                    "Connection Failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                Button("Retry") {
                    Task {
                        do {
                            try await manager.connect(peripheral: peripheral)
                        } catch {
                            manager.connectionError = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var serviceList: some View {
        List {
            if manager.discoveredServices.isEmpty {
                Section {
                    HStack {
                        ProgressView()
                        Text("Discovering services…")
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
            } else {
                ForEach(manager.discoveredServices, id: \.uuid) { service in
                    Section(header: Text(service.uuid.uuidString).font(.caption)) {
                        let characteristics = service.characteristics ?? []
                        if characteristics.isEmpty {
                            Text("No characteristics")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        } else {
                            ForEach(characteristics, id: \.uuid) { characteristic in
                                CharacteristicSummaryRow(characteristic: characteristic)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct CharacteristicSummaryRow: View {
    let characteristic: CBCharacteristic

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(characteristic.uuid.uuidString)
                .font(.caption.monospaced())
            Text(propertiesDescription)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var propertiesDescription: String {
        var props: [String] = []
        let p = characteristic.properties
        if p.contains(.read)   { props.append("Read") }
        if p.contains(.write)  { props.append("Write") }
        if p.contains(.notify) { props.append("Notify") }
        if p.contains(.indicate) { props.append("Indicate") }
        if p.contains(.writeWithoutResponse) { props.append("WriteNoResp") }
        return props.isEmpty ? "No properties" : props.joined(separator: " · ")
    }
}
