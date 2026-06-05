import SwiftUI

@main
struct ConnectivityLabApp: App {
    @State private var bleManager = BLEManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.bleManager, bleManager)
        }
    }
}
