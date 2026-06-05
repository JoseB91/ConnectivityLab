import SwiftUI
import CoreBluetooth

struct CharacteristicWriteSheet: View {
    let characteristic: CBCharacteristic
    let peripheral: CBPeripheral
    @Binding var draft: String
    var onWrite: (CBCharacteristicWriteType) -> Void

    @FocusState private var inputFocused: Bool
    @State private var writeType: CBCharacteristicWriteType = .withResponse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Value") {
                    TextField("Enter value", text: $draft)
                        .focused($inputFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if supportsWriteWithResponse && supportsWriteWithoutResponse {
                    Section("Write Type") {
                        Picker("Write Type", selection: $writeType) {
                            Text("With Response").tag(CBCharacteristicWriteType.withResponse)
                            Text("Without Response").tag(CBCharacteristicWriteType.withoutResponse)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                    }
                }
            }
            .navigationTitle("Write Characteristic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Write") {
                        onWrite(writeType)
                        dismiss()
                    }
                    .disabled(draft.isEmpty)
                }
            }
            .onAppear { inputFocused = true }
        }
    }

    private var supportsWriteWithResponse: Bool {
        characteristic.properties.contains(.write)
    }

    private var supportsWriteWithoutResponse: Bool {
        characteristic.properties.contains(.writeWithoutResponse)
    }
}
