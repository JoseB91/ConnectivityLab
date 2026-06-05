import CoreBluetooth
import Observation

@Observable
final class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, DeviceTransport {
    var peripherals: [(peripheral: CBPeripheral, rssi: Int)] = []
    var isConnected = false
    var isScanning = false
    var stateError: String? = nil
    var connectionError: String? = nil
    var connectedPeripheral: CBPeripheral? = nil
    var selectedPeripheral: CBPeripheral? = nil
    var discoveredServices: [CBService] = []
    var connectingPeripheralID: UUID? = nil
    var characteristics: [CBUUID: [CBCharacteristic]] = [:]
    var lastValues: [CBUUID: Data] = [:]
    var writeResults: [CBUUID: Result<Void, Error>] = [:]
    var subscribedUUIDs: Set<CBUUID> = []

    private var central: CBCentralManager!
    private var scanTask: Task<Void, Never>?
    private var connectContinuation: CheckedContinuation<Void, Error>?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard central.state == .poweredOn else { return }
        peripherals.removeAll()
        isScanning = true
        central.scanForPeripherals(withServices: nil, options: nil)

        scanTask?.cancel()
        scanTask = Task {
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            stopScan()
        }
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        scanTask?.cancel()
        scanTask = nil
    }

    // MARK: - DeviceTransport

    func connect() async throws {
        // Generic connect — no-op without a selected peripheral; use connect(peripheral:) instead
    }

    func connect(peripheral: CBPeripheral) async throws {
        connectionError = nil
        connectingPeripheralID = peripheral.identifier
        stopScan()

        try await withCheckedThrowingContinuation { continuation in
            connectContinuation = continuation
            peripheral.delegate = self
            central.connect(peripheral, options: nil)
        }
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        stopScan()
        isConnected = false
        connectedPeripheral = nil
        selectedPeripheral = nil
        connectingPeripheralID = nil
        discoveredServices = []
        characteristics = [:]
        lastValues = [:]
        writeResults = [:]
        subscribedUUIDs = []
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            stateError = nil
        case .poweredOff:
            stateError = "Bluetooth is off."
        case .unauthorized:
            stateError = "Bluetooth permission denied."
        case .unsupported:
            stateError = "Bluetooth not supported on this device."
        default:
            stateError = "Bluetooth unavailable."
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rssiValue = RSSI.intValue
        if let idx = peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
            peripherals[idx] = (peripheral, rssiValue)
        } else {
            peripherals.append((peripheral, rssiValue))
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectedPeripheral = peripheral
        connectingPeripheralID = nil
        peripheral.discoverServices(nil)
        connectContinuation?.resume()
        connectContinuation = nil
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let message = error?.localizedDescription ?? "Connection failed."
        connectionError = message
        connectingPeripheralID = nil
        connectContinuation?.resume(throwing: error ?? NSError(domain: "BLE", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: message]))
        connectContinuation = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        selectedPeripheral = nil
        connectingPeripheralID = nil
        discoveredServices = []
        characteristics = [:]
        lastValues = [:]
        writeResults = [:]
        subscribedUUIDs = []
        if let error {
            connectionError = error.localizedDescription
        }
        // Resume continuation if we disconnected before didConnect fired
        connectContinuation?.resume(throwing: error ?? NSError(domain: "BLE", code: -2,
                                    userInfo: [NSLocalizedDescriptionKey: "Disconnected unexpectedly."]))
        connectContinuation = nil
    }

    // MARK: - CBPeripheralDelegate

    func discoverCharacteristics(for service: CBService) {
        connectedPeripheral?.discoverCharacteristics(nil, for: service)
    }

    func subscribe(to characteristic: CBCharacteristic) {
        connectedPeripheral?.setNotifyValue(true, for: characteristic)
    }

    func unsubscribe(from characteristic: CBCharacteristic) {
        connectedPeripheral?.setNotifyValue(false, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let discovered = peripheral.services else { return }
        discoveredServices = discovered
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        characteristics[service.uuid] = service.characteristics ?? []
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        lastValues[characteristic.uuid] = data
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else { return }
        if characteristic.isNotifying {
            subscribedUUIDs.insert(characteristic.uuid)
        } else {
            subscribedUUIDs.remove(characteristic.uuid)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            writeResults[characteristic.uuid] = .failure(error)
        } else {
            writeResults[characteristic.uuid] = .success(())
        }
    }
}
