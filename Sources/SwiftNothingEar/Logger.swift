import Foundation
import os.log

enum Logger {

    private static let subsystem = "\(Bundle.main.bundleIdentifier ?? "com").NothingEar"

    /// Bluetooth operations and communication
    static let bluetooth = os.Logger(subsystem: subsystem, category: "bluetooth")

    /// Connection management and state
    static let connection = os.Logger(subsystem: subsystem, category: "connection")

    /// Parsing and processing device data
    static let parsing = os.Logger(subsystem: subsystem, category: "parsing")

    /// General library operations
    static let general = os.Logger(subsystem: subsystem, category: "general")
}

extension Logger {

    /// Log raw Bluetooth data in human-readable format
    static func logBluetoothData(_ data: [UInt8], direction: BluetoothDataDirection) {
        let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")

        switch direction {
        case .outgoing:
            bluetooth.debug("📤 Raw request: [\(hexString, privacy: .public)]")
        case .incoming:
            bluetooth.debug("📥 Raw response: [\(hexString, privacy: .public)]")
        }
    }

    enum BluetoothDataDirection {
        case outgoing
        case incoming
    }
}
