# ConnectivityLab — BLE & Wi-Fi Tester

Simple single-screen iOS app to explore BLE and Wi-Fi device connectivity.

---

## Project Goal

A developer scratch pad — one screen, no nav stack — to:
- Scan and list nearby BLE peripherals
- Ping a local Wi-Fi host and measure round-trip time
- Toggle between both modes with a segmented control

---

## Stack

| Layer | Choice |
|---|---|
| Language | Swift 5.10 |
| UI | SwiftUI |
| BLE | CoreBluetooth |
| Wi-Fi / Network | Network.framework + URLSession |
| Min target | iOS 17 |
| Architecture | MVVM (one ViewModel per transport) |

---

## File Structure

```
ConnectivityLab/
├── ConnectivityLabApp.swift
├── ContentView.swift               ← single screen, segmented picker
│
├── BLE/
│   ├── BLEManager.swift            ← CBCentralManager, scan, list peripherals
│   └── BLEDeviceRow.swift          ← row: name · RSSI signal bar · connect button
│
├── WiFi/
│   ├── WiFiPinger.swift            ← ping host via URLSession, measure ms
│   └── WiFiStatusView.swift        ← host input + latency display
│
└── Shared/
    ├── DeviceTransport.swift       ← protocol: connect / send / receive
    └── SignalStrengthView.swift    ← reusable RSSI bar (1–5 dots)
```

---

## Core Protocol

```swift
// Shared/DeviceTransport.swift
protocol DeviceTransport {
    var isConnected: Bool { get }
    func connect() async throws
    func disconnect()
}
```

Both `BLEManager` and `WiFiPinger` conform to `DeviceTransport`.

---

## BLE Behavior

- On appear → `centralManager.scanForPeripherals(withServices: nil)`
- List updates every time `didDiscover peripheral` fires
- Each row shows: **name** (or "Unknown") · **RSSI** · connect/disconnect toggle
- Stop scan after 10 s to save battery

```swift
// BLE/BLEManager.swift  — skeleton
@Observable
final class BLEManager: NSObject, CBCentralManagerDelegate, DeviceTransport {
    var peripherals: [CBPeripheral] = []
    var isConnected = false
    private var central: CBCentralManager!

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
        }
    }

    func connect() async throws { /* connect to selected peripheral */ }
    func disconnect() { central.stopScan() }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
}
```

---

## Wi-Fi Behavior

- Text field for host (default: `192.168.1.1`)
- "Ping" button → HEAD request via `URLSession`, measures ms
- Shows: ✅ reachable + latency | ❌ timeout/error

```swift
// WiFi/WiFiPinger.swift — skeleton
@Observable
final class WiFiPinger: DeviceTransport {
    var host = "192.168.1.1"
    var latencyMs: Double? = nil
    var isConnected = false
    var errorMessage: String? = nil

    func connect() async throws {
        let url = URL(string: "http://\(host)")!
        let start = Date()
        let (_, response) = try await URLSession.shared.data(from: url)
        latencyMs = Date().timeIntervalSince(start) * 1000
        isConnected = (response as? HTTPURLResponse)?.statusCode != nil
    }

    func disconnect() {
        isConnected = false
        latencyMs = nil
    }
}
```

---

## ContentView Layout

```
┌─────────────────────────────────┐
│  ConnectivityLab                │
│  ┌──────────┬──────────┐        │
│  │  BLE     │  Wi-Fi   │  ← segmented picker
│  └──────────┴──────────┘        │
│                                 │
│  [BLE mode]                     │
│  ● Device A        ████░  -62   │
│  ● Unknown         ██░░░  -81   │
│  ○ Device B        █████  -45   │
│                 [Scan / Stop]   │
│                                 │
│  [Wi-Fi mode]                   │
│  Host: [192.168.1.1        ]    │
│        [ Ping ]                 │
│  ✅  23.4 ms                    │
└─────────────────────────────────┘
```

---

## Info.plist Keys Required

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Used to scan nearby BLE devices during development.</string>

<key>NSLocalNetworkUsageDescription</key>
<string>Used to ping devices on your local Wi-Fi network.</string>
```

---

## Out of Scope (keep it simple)

- No persistence
- No background modes
- No GATT characteristic read/write (next step after this works)
- No authentication

---

## Success Criteria

- [ ] BLE scan shows live list of nearby peripherals with RSSI
- [ ] Wi-Fi ping returns latency to a local host
- [ ] Switching modes doesn't crash or leak resources
- [ ] No hardcoded device UUIDs — works with any hardware
