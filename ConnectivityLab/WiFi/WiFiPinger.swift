import Foundation
import Observation

@Observable
final class WiFiPinger: DeviceTransport {
    var host = "192.168.1.1"
    var latencyMs: Double? = nil
    var isConnected = false
    var errorMessage: String? = nil
    var isPinging = false

    func connect() async throws {
        guard let url = URL(string: "http://\(host)") else {
            errorMessage = "Invalid host."
            return
        }

        isPinging = true
        errorMessage = nil
        latencyMs = nil

        defer { isPinging = false }

        do {
            var request = URLRequest(url: url, timeoutInterval: 5)
            request.httpMethod = "HEAD"

            let start = Date()
            let (_, response) = try await URLSession.shared.data(for: request)
            let elapsed = Date().timeIntervalSince(start) * 1000

            if let http = response as? HTTPURLResponse {
                latencyMs = elapsed
                isConnected = (100..<600).contains(http.statusCode)
            } else {
                errorMessage = "Unexpected response."
                isConnected = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isConnected = false
        }
    }

    func disconnect() {
        isConnected = false
        latencyMs = nil
        errorMessage = nil
    }
}
