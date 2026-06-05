import SwiftUI

private struct BLEManagerKey: EnvironmentKey {
    static let defaultValue = BLEManager()
}

extension EnvironmentValues {
    var bleManager: BLEManager {
        get { self[BLEManagerKey.self] }
        set { self[BLEManagerKey.self] = newValue }
    }
}
