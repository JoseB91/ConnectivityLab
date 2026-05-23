# ConnectivityLab — Task List

## Project Setup

- [x] Create Xcode project (`ConnectivityLab`, SwiftUI, iOS 17 minimum) — **manual: File → New → Project in Xcode, then drag in the ConnectivityLab/ folder**
- [x] Set up folder structure: `BLE/`, `WiFi/`, `Shared/`
- [x] Add `NSBluetoothAlwaysUsageDescription` to Info.plist — **manual: add in Xcode target → Info tab**
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

## GATT (Next Step After Scan)

- [ ] `BLE/BLEManager.swift` — wire up real connection lifecycle
  - [ ] Implement `connect(peripheral:)` — call `central.connect(peripheral)`
  - [ ] Handle `centralManager(_:didConnect:)` — set `isConnected = true`, kick off service discovery
  - [ ] Handle `centralManager(_:didFailToConnect:error:)` — surface error
  - [ ] Handle `centralManager(_:didDisconnectPeripheral:error:)` — set `isConnected = false`
  - [ ] Conform to `CBPeripheralDelegate` for service / characteristic discovery
- [ ] `BLE/GATTExplorerView.swift` — drill-down view for a connected peripheral
  - [ ] List discovered services (UUID + name lookup for known SIG-assigned UUIDs)
  - [ ] List characteristics per service with properties (read / write / notify / indicate)
  - [ ] Read characteristic value on tap (`peripheral.readValue(for:)`)
  - [ ] Toggle notify subscription (`peripheral.setNotifyValue(true, for:)`)
  - [ ] Hex / UTF-8 viewer for raw value bytes
- [ ] Write support — text or hex input, with / without response
- [ ] Battery Service demo (`0x180F` / `0x2A19`) — read percentage from any standard peripheral

---

## OTA Firmware Updates

- [ ] Pick a target stack to support first (Nordic DFU, Apple Accessory Setup Kit, custom)
- [ ] `BLE/OTAUpdater.swift` — `@Observable` service that owns the transfer state machine
  - [ ] Load firmware file from `.fileImporter` (`.zip` / `.bin`)
  - [ ] Chunk + write packets to the DFU control / data characteristics
  - [ ] Track progress (`bytesSent / totalBytes`) and expose as `Double` for `ProgressView`
  - [ ] Handle reset-to-bootloader handshake
  - [ ] Verify checksum / CRC on completion
- [ ] `BLE/OTAUpdateView.swift` — file picker, progress bar, cancel, success / failure UI
- [ ] Resume / retry behavior on transient disconnect
- [ ] Validate against a real dev kit (e.g. nRF52 DK with Nordic DFU bootloader)

---

## Matter / Thread

- [ ] Add `MatterSupport` capability — **manual: target → Signing & Capabilities → + Capability → Matter**
- [ ] Add Thread network credentials entitlement — **manual: same place, "Network Extensions" → Thread**
- [ ] `Matter/MatterCommissioner.swift` — wrap `MatterAddDeviceRequest` for onboarding
  - [ ] Trigger commissioning flow from a QR / setup code
  - [ ] Hand off to Home app for fabric join
- [ ] Display the device's Thread / Wi-Fi role once commissioned (router / end device)
- [ ] `Thread/ThreadStatusView.swift` — surface border router presence via `NWBrowser` for `_meshcop._udp`
- [ ] Investigate `ThreadNetwork` framework for reading active dataset (requires entitlement from Apple)

---

## HomeKit

- [ ] Add HomeKit capability — **manual: target → Signing & Capabilities → + Capability → HomeKit**
- [ ] Add `NSHomeKitUsageDescription` to Info.plist
- [ ] `HomeKit/HomeKitManager.swift` — `@Observable` wrapper around `HMHomeManager`
  - [ ] Conform to `HMHomeManagerDelegate`
  - [ ] Expose primary home, rooms, accessories
  - [ ] Refresh on `homeManagerDidUpdateHomes`
- [ ] `HomeKit/AccessoryListView.swift` — list rooms → accessories → services → characteristics
  - [ ] Toggle a `HMCharacteristic` (e.g. power state of a lightbulb)
  - [ ] Read current value via `readValue(completionHandler:)`
  - [ ] Subscribe to updates via `enableNotification(true, ...)`
- [ ] Add a fourth segment to the main `Picker` ("HomeKit") and route to `AccessoryListView`
- [ ] Test against the HomeKit Accessory Simulator (Additional Tools for Xcode) — **manual: download from developer.apple.com**
