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

    @State private var expandedServiceID: CBUUID? = nil

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
                    let isExpanded = expandedServiceID == service.uuid
                    Section {
                        // Tappable header row acting as disclosure toggle
                        Button {
                            if isExpanded {
                                expandedServiceID = nil
                            } else {
                                expandedServiceID = service.uuid
                                if manager.characteristics[service.uuid] == nil {
                                    manager.discoverCharacteristics(for: service)
                                }
                            }
                        } label: {
                            HStack {
                                Text(service.uuid.uuidString)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        if isExpanded {
                            if let chars = manager.characteristics[service.uuid] {
                                if chars.isEmpty {
                                    Text("No characteristics")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                } else {
                                    ForEach(chars, id: \.uuid) { characteristic in
                                        CharacteristicRow(
                                            characteristic: characteristic,
                                            peripheral: peripheral,
                                            lastReadValue: Binding(
                                                get: { manager.lastValues[characteristic.uuid] },
                                                set: { manager.lastValues[characteristic.uuid] = $0 }
                                            )
                                        )
                                    }
                                }
                            } else {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Loading…")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: expandedServiceID)
        .animation(.default, value: manager.characteristics.keys.map(\.uuidString).sorted())
    }
}

