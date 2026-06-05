import SwiftUI
import CoreBluetooth

struct CharacteristicRow: View {
    let characteristic: CBCharacteristic
    let peripheral: CBPeripheral
    @Binding var lastReadValue: Data?
    var writeResult: Result<Void, Error>?
    var isSubscribed: Bool = false
    var onSubscribeToggle: (() -> Void)? = nil

    @State private var isReading = false
    @State private var showWriteSheet = false
    @State private var writeDraft = ""

    private var canRead: Bool { characteristic.properties.contains(.read) }
    private var canWrite: Bool {
        characteristic.properties.contains(.write) ||
        characteristic.properties.contains(.writeWithoutResponse)
    }
    private var canNotify: Bool {
        characteristic.properties.contains(.notify) ||
        characteristic.properties.contains(.indicate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(characteristic.uuid.uuidString)
                            .font(.caption.monospaced())
                        if isSubscribed {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .liveValueBadge(trigger: lastReadValue)
                        }
                    }
                    Text(propertiesDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if canNotify {
                    Button(isSubscribed ? "Unsub" : "Notify") {
                        onSubscribeToggle?()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .tint(isSubscribed ? .blue : nil)
                }

                if canRead {
                    Button("Read") {
                        isReading = true
                        peripheral.readValue(for: characteristic)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(isReading)
                    .pulse(active: isReading)
                }

                if canWrite {
                    Button("Write") {
                        showWriteSheet = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }

            if let data = lastReadValue {
                valuePreview(data)
                    .liveValueBadge(trigger: isSubscribed ? data : nil)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let result = writeResult {
                writeResultBadge(result)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 2)
        .animation(.default, value: lastReadValue)
        .animation(.default, value: writeResult.map { if case .success = $0 { return true } else { return false } })
        .onChange(of: lastReadValue) { _, _ in isReading = false }
        .sheet(isPresented: $showWriteSheet) {
            CharacteristicWriteSheet(
                characteristic: characteristic,
                peripheral: peripheral,
                draft: $writeDraft
            ) { writeType in
                guard let data = writeDraft.data(using: .utf8) else { return }
                peripheral.writeValue(data, for: characteristic, type: writeType)
            }
        }
    }

    private func valuePreview(_ data: Data) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(data.map { String(format: "%02X", $0) }.joined(separator: " "))
                .font(.caption2.monospaced())
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let utf8 = String(data: data, encoding: .utf8), !utf8.isEmpty {
                Text("\"\(utf8)\"")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(6)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

    private func writeResultBadge(_ result: Result<Void, Error>) -> some View {
        HStack(spacing: 4) {
            switch result {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Write succeeded")
            case .failure(let error):
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text(error.localizedDescription)
            }
        }
        .font(.caption2)
        .padding(6)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

    private var propertiesDescription: String {
        var props: [String] = []
        let p = characteristic.properties
        if p.contains(.read)                 { props.append("Read") }
        if p.contains(.write)                { props.append("Write") }
        if p.contains(.notify)               { props.append("Notify") }
        if p.contains(.indicate)             { props.append("Indicate") }
        if p.contains(.writeWithoutResponse) { props.append("WriteNoResp") }
        return props.isEmpty ? "No properties" : props.joined(separator: " · ")
    }
}
