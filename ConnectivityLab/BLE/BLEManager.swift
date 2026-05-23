import CoreBluetooth
import Observation

@Observable
final class BLEManager: NSObject, CBCentralManagerDelegate, DeviceTransport {
    var peripherals: [(peripheral: CBPeripheral, rssi: Int)] = []
    var isConnected = false
    var isScanning = false
    var stateError: String? = nil

    private var central: CBCentralManager!
    private var scanTask: Task<Void, Never>?

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

    func connect() async throws {
        // Reserved for GATT connection to a selected peripheral
    }

    func disconnect() {
        stopScan()
        isConnected = false
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
}
