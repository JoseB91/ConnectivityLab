# ConnectivityLab — Architecture

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Language | Swift 5.10 | Strict concurrency (`async/await`) |
| UI | SwiftUI | iOS 17 — no UIKit wrappers needed |
| State | `@Observable` (Observation framework) | Replaces `@ObservedObject`/`@StateObject` |
| BLE | CoreBluetooth | `CBCentralManager` + delegate callbacks |
| Network | URLSession | HTTP HEAD/GET for Wi-Fi round-trip timing |
| Min target | iOS 17 | Required for `@Observable` and modern SwiftUI APIs |
| Architecture | MVVM | One ViewModel (`BLEManager`, `WiFiPinger`) per transport |

---

## Pattern: MVVM

```
View  ──observes──►  ViewModel  ──drives──►  Framework / OS
```

- **Views** are pure SwiftUI structs — no business logic.
- **ViewModels** (`BLEManager`, `WiFiPinger`) hold state and talk to OS APIs.
- `@Observable` propagates state changes without boilerplate.

---

## Module Map

```
ConnectivityLab/
│
├── ConnectivityLabApp.swift          @main entry point
├── ContentView.swift                 Single screen; segmented picker; routes to BLE or Wi-Fi subview
│
├── Shared/
│   ├── DeviceTransport.swift         Protocol: isConnected · connect() · disconnect()
│   └── SignalStrengthView.swift      Reusable RSSI dot bar (maps dBm → 1–5 dots)
│
├── BLE/
│   ├── BLEManager.swift              ViewModel — CBCentralManager, scan loop, peripheral list
│   └── BLEDeviceRow.swift            Row view — name · RSSI bar · connect toggle
│
└── WiFi/
    ├── WiFiPinger.swift              ViewModel — URLSession ping, latency measurement
    └── WiFiStatusView.swift          View — host input, ping button, latency / error display
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

Both `BLEManager` and `WiFiPinger` conform to `DeviceTransport`, allowing `ContentView` to call a unified interface regardless of the active transport.

---

## BLE Data Flow

```
CBCentralManager
  │  didDiscover peripheral
  ▼
BLEManager.peripherals: [CBPeripheral]   (@Observable — auto-updates UI)
  │
  ▼
ContentView / BLEDeviceRow               renders list, RSSI bar, connect button
```

- Scan starts on `.onAppear`, stops after **10 s** (battery guard) or on `.onDisappear`.
- RSSI is polled per `didDiscover` callback; no manual timer needed.

---

## Wi-Fi Data Flow

```
User taps Ping
  │
  ▼
WiFiPinger.connect()
  │  URLSession GET to http://<host>
  ▼
latencyMs = (response time) * 1000     (@Observable — auto-updates UI)
  │
  ▼
WiFiStatusView                          shows ✅ Xms or ❌ error
```

- `connect()` is `async throws`; the view disables the button while in-flight.
- Timeout and network errors surface through `errorMessage`.

---

## Key iOS APIs

| API | Used for |
|---|---|
| `CBCentralManager` | BLE scanning and peripheral discovery |
| `CBCentralManagerDelegate` | State updates and peripheral callbacks |
| `URLSession.shared.data(from:)` | Wi-Fi latency measurement |
| `@Observable` | Reactive state without Combine overhead |
| `async / await` | Structured concurrency for connect/ping |
| `Task.sleep` | 10 s BLE scan auto-stop |

---

## Info.plist Permissions

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Used to scan nearby BLE devices during development.</string>

<key>NSLocalNetworkUsageDescription</key>
<string>Used to ping devices on your local Wi-Fi network.</string>
```

---

## Intentional Constraints

| Out of scope | Reason |
|---|---|
| Persistence (CoreData / SwiftData) | Scratch-pad app; state is ephemeral |
| Background modes | Unnecessary complexity for a dev tool |
| GATT characteristic read/write | Next iteration after basic connect works |
| Authentication | Not required for local network / BLE scan |
| Navigation stack | Single-screen design by intent |
