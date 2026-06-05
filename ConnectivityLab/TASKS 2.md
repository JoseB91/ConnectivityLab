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

---

## GATT & SwiftUI Concepts

Each task pairs a GATT capability with a SwiftUI property-wrapper / view concept to practice.

### 1. Inject Manager via `@Environment`
- [x] `Shared/BLEManagerKey.swift` (new)
  - [x] Define `EnvironmentValues.bleManager` with a custom `EnvironmentKey`
- [x] `ConnectivityLabApp.swift`
  - [x] Construct `BLEManager` once and inject via `.environment(\.bleManager, manager)`
- [x] Refactor `ContentView` and `BLEListView` to read from `@Environment(\.bleManager)` instead of prop-drilling
- [x] Rationale: every subsequent task adds a view that needs the manager — wire this first to avoid refactoring later

### 2. Connect & Discover Services — `@Bindable`
- [x] `BLE/BLEManager.swift`
  - [x] Add `selectedPeripheral: CBPeripheral?` and `discoveredServices: [CBService]`
  - [x] Add `connectingPeripheralID: UUID?` for in-flight connect state
  - [x] Implement `connect()` for the selected peripheral; call `centralManager.connect(_:)`
  - [x] Conform to `CBPeripheralDelegate`; on `didConnect`, call `discoverServices(nil)`
  - [x] Implement `peripheral(_:didDiscoverServices:)` → populate `discoveredServices`
- [x] `BLE/BLEDeviceDetailView.swift` (new)
  - [x] Receive `@Bindable var manager: BLEManager` (iOS 17 `@Observable` binding pattern)
  - [x] List services by UUID
  - [x] Push from `BLEDeviceRow` tap

### 3. Scanning / Connecting Visual Feedback — `ViewModifier` + animation
- [x] `Shared/PulseModifier.swift` (new)
  - [x] `ViewModifier` driven by `@State private var isPulsing` + `.onAppear` toggle
  - [x] `withAnimation(.easeInOut.repeatForever())` on opacity / scale
  - [x] Extension: `View.pulse(active:)`
- [x] Apply to:
  - [x] BLE "Scanning…" header while `isScanning == true`
  - [x] `BLEDeviceRow` while `manager.connectingPeripheralID == peripheral.identifier`
- [x] Rationale: built early so tasks 4–7 can reuse it for in-flight read/write/notify states

### 4. Discover Characteristics — `@State`
- [ ] `BLE/BLEManager.swift`
  - [ ] Cache `characteristics: [CBUUID: [CBCharacteristic]]` keyed by service UUID
  - [ ] Implement `peripheral(_:didDiscoverCharacteristicsFor:error:)`
- [ ] `BLE/BLEDeviceDetailView.swift`
  - [ ] `@State private var expandedServiceID: CBUUID?` to toggle disclosure rows
  - [ ] Trigger `discoverCharacteristics(nil, for:)` when a service expands

### 5. Read Characteristic — `@Binding`
- [ ] `BLE/CharacteristicRow.swift` (new)
  - [ ] Accept `let characteristic: CBCharacteristic` and `@Binding var lastReadValue: Data?`
  - [ ] "Read" button calls `peripheral.readValue(for:)`
  - [ ] Render hex + UTF-8 preview of `lastReadValue`
  - [ ] Apply `.pulse(active:)` while the read is in-flight
- [ ] `BLE/BLEManager.swift`
  - [ ] Implement `peripheral(_:didUpdateValueFor:error:)` → publish via `lastValues: [CBUUID: Data]`

### 6. Write Characteristic — `@FocusState` + `@Binding<String>`
- [ ] `BLE/CharacteristicWriteSheet.swift` (new)
  - [ ] `@Binding var draft: String`
  - [ ] `@FocusState private var inputFocused: Bool` (auto-focus on appear)
  - [ ] Segmented control: write type `.withResponse` / `.withoutResponse`
  - [ ] Submit → `peripheral.writeValue(_:for:type:)`
- [ ] `BLE/BLEManager.swift`
  - [ ] Implement `peripheral(_:didWriteValueFor:error:)` → surface success/error

### 7. Notifications / Indications — Custom `ViewModifier`
- [ ] `BLE/BLEManager.swift`
  - [ ] `subscribe(to:)` → `peripheral.setNotifyValue(true, for:)`
  - [ ] Re-emit updates through the existing `lastValues` map
- [ ] `Shared/LiveValueBadgeModifier.swift` (new)
  - [ ] `ViewModifier` that pulses opacity/scale when its observed value changes
  - [ ] Extension: `View.liveValueBadge(trigger: Data?)`
  - [ ] Apply to `CharacteristicRow` so subscribed values visibly pulse on each update

### 8. Persist Last-Connected Peripheral — Custom `@propertyWrapper`
- [ ] `Shared/UserDefault.swift` (new)
  - [ ] `@propertyWrapper struct UserDefault<Value>` with `key`, `defaultValue`, `UserDefaults` storage
- [ ] `BLE/BLEManager.swift`
  - [ ] `@UserDefault("lastPeripheralUUID", default: nil) var lastPeripheralUUID: String?`
  - [ ] On `didConnect`, store `peripheral.identifier.uuidString`
  - [ ] On launch, attempt `retrievePeripherals(withIdentifiers:)` + auto-reconnect
- [ ] Rationale: depends on `connect()` already working, so it lands last

---

## Validation for GATT Phase

- [ ] Connect to a real BLE peripheral and list its services
- [ ] Read at least one characteristic value (hex view renders)
- [ ] Write a value to a writable characteristic (confirm callback fires)
- [ ] Subscribe to a notifying characteristic; pulse modifier fires on each update
- [ ] Force-quit and relaunch → app auto-reconnects to last peripheral via `@UserDefault`
- [ ] No retain cycles: backgrounding the app and returning leaves no zombie connections
