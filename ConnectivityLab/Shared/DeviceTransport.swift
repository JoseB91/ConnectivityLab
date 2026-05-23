import Foundation

protocol DeviceTransport {
    var isConnected: Bool { get }
    func connect() async throws
    func disconnect()
}
