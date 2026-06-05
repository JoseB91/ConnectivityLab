import SwiftUI
import CoreBluetooth

struct CharacteristicRow: View {
    let characteristic: CBCharacteristic
    let peripheral: CBPeripheral
    @Binding var lastReadValue: Data?

    @State private var isReading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(characteristic.uuid.uuidString)
                        .font(.caption.monospaced())
                    Text(propertiesDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if characteristic.properties.contains(.read) {
                    Button("Read") {
                        isReading = true
                        peripheral.readValue(for: characteristic)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(isReading)
                    .pulse(active: isReading)
                }
            }

            if let data = lastReadValue {
                valuePreview(data)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 2)
        .animation(.default, value: lastReadValue)
        .onChange(of: lastReadValue) { _, _ in
            isReading = false
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
