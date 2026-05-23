# ConnectivityLab — Task List

## Project Setup

- [x] Create Xcode project (`ConnectivityLab`, SwiftUI, iOS 17 minimum) — **manual: File → New → Project in Xcode, then drag in the ConnectivityLab/ folder**
- [x] Set up folder structure: `BLE/`, `WiFi/`, `Shared/`
- [ ] Add `NSBluetoothAlwaysUsageDescription` to Info.plist — **manual: add in Xcode target → Info tab**
- [ ] Add `NSLocalNetworkUsageDescription` to Info.plist — **manual: add in Xcode target → Info tab**

---

## Shared Layer

- [x] `Shared/DeviceTransport.swift` — define `DeviceTransport` protocol (`isConnected`, `connect()`, `disconnect()`)
- [x] `Shared/SignalStrengthView.swift` — reusable RSSI dot bar (1–5 filled dots based on dBm range)

---

## BLE Module

- [x] `BLE/BLEManager.swift`
  - [x] `@Observable` class conforming to `CBCentralManagerDelegate` and `DeviceTransport`
  - [x] Initialize `CBCentralManager` on `init()`
  - [x] `startScan()` — guard `.poweredOn`, call `scanForPeripherals(withServices: nil)`
  - [x] `centralManager(_:didDiscover:advertisementData:rssi:)` — append unique peripherals
  - [x] Auto-stop scan after 10 seconds (use `Task.sleep`)
  - [x] `connect() async throws` — stub (reserved for GATT)
  - [x] `disconnect()` — stop scan, set `isConnected = false`
  - [x] Handle `centralManagerDidUpdateState` (show error if not `.poweredOn`)

- [x] `BLE/BLEDeviceRow.swift`
  - [x] Display peripheral name (fallback: "Unknown")
  - [x] Show `SignalStrengthView` for RSSI
  - [x] Show raw RSSI value (dBm)
  - [x] Scan / Stop button (in `BLEListView`)

---

## Wi-Fi Module

- [x] `WiFi/WiFiPinger.swift`
  - [x] `@Observable` class conforming to `DeviceTransport`
  - [x] `host` property (default: `"192.168.1.1"`)
  - [x] `connect() async throws` — HEAD via `URLSession`, measure round-trip ms
  - [x] `disconnect()` — reset `isConnected` and `latencyMs`
  - [x] `errorMessage` property for timeout / unreachable feedback

- [x] `WiFi/WiFiStatusView.swift`
  - [x] Text field bound to `WiFiPinger.host`
  - [x] "Ping" button triggers `pinger.connect()`
  - [x] Display latency (✅ X ms) or error (❌ message)
  - [x] Disable button while a ping is in-flight

---

## Main Screen

- [x] `ContentView.swift`
  - [x] `Picker` (segmented style) to toggle BLE / Wi-Fi mode
  - [x] Conditional rendering: `BLEListView` or `WiFiStatusView`
  - [x] Start BLE scan on `.onAppear`, stop on `.onDisappear`
  - [x] Navigation title: "ConnectivityLab"

- [x] `ConnectivityLabApp.swift` — `@main` entry point

---

## Quality & Validation

- [ ] BLE scan shows live peripheral list with RSSI updating
- [ ] Wi-Fi ping returns latency to a reachable local host
- [ ] Switching modes does not crash or leak resources
- [ ] App works with any BLE hardware (no hardcoded UUIDs)
- [ ] Simulator smoke-test for Wi-Fi path; physical device test for BLE
