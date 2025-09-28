import Foundation
@preconcurrency import CoreBluetooth

extension NothingEar {

    struct ServiceUUID {
        let uuid: CBUUID
        let writeCharacteristicUUID: CBUUID
        let notifyCharacteristicUUID: CBUUID
    }

    enum BluetoothCommand {

        enum RequestRead {
            static let advancedEQ: UInt16      = 49228 // 0xC04C
            static let anc: UInt16             = 49182 // 0xC01E
            static let battery: UInt16         = 49159 // 0xC007
            static let customEQ: UInt16        = 49220 // 0xC044
            static let enhancedBass: UInt16    = 49230 // 0xC04E
            static let eq: UInt16              = 49183 // 0xC01F
            static let firmware: UInt16        = 49218 // 0xC042
            static let gesture: UInt16         = 49176 // 0xC018
            static let inEarDetection: UInt16  = 49166 // 0xC00E
            static let lowLatency: UInt16      = 49217 // 0xC041
            static let ledCaseColor: UInt16    = 49175 // 0xC017
            static let listeningMode: UInt16   = 49232 // 0xC050
            static let personalizedANC: UInt16 = 49184 // 0xC020
            static let serialNumber: UInt16    = 49158 // 0xC006
            static let spatialAudio: UInt16    = 49231 // 0xC04F
        }

        enum RequestWrite {
            static let advancedEQ: UInt16      = 61519 // 0xF06F
            static let anc: UInt16             = 61455 // 0xF00F
            static let customEQ: UInt16        = 61505 // 0xF061
            static let earFitTest: UInt16      = 61460 // 0xF014
            static let enhancedBass: UInt16    = 61521 // 0xF071
            static let eq: UInt16              = 61456 // 0xF010
            static let gesture: UInt16         = 61443 // 0xF003
            static let inEarDetection: UInt16  = 61444 // 0xF004
            static let lowLatency: UInt16      = 61504 // 0xF060
            static let ledCaseColor: UInt16    = 61453 // 0xF00D
            static let listeningMode: UInt16   = 61469 // 0xF01D
            static let personalizedANC: UInt16 = 61457 // 0xF011
            static let ringBuds: UInt16        = 61442 // 0xF002
            static let spatialAudio: UInt16    = 61522 // 0xF052
        }

        enum Response {
            static let advancedEQ: UInt16      = 16460 // 0x404C
            static let ancA: UInt16            = 57347 // 0xE003
            static let ancB: UInt16            = 16414 // 0x401E
            static let batteryA: UInt16        = 57345 // 0xE001
            static let batteryB: UInt16        = 16391 // 0x4007
            static let customEQ: UInt16        = 16452 // 0x4044
            static let earFitTest: UInt16      = 57357 // 0xE00D
            static let enhancedBass: UInt16    = 16462 // 0x404E
            static let eqA: UInt16             = 16415 // 0x401F
            static let eqB: UInt16             = 16464 // 0x4040
            static let firmware: UInt16        = 16450 // 0x4042
            static let gesture: UInt16         = 16408 // 0x4018
            static let inEarDetection: UInt16  = 16398 // 0x400E
            static let lowLatency: UInt16      = 16449 // 0x4041
            static let ledCaseColor: UInt16    = 16407 // 0x4017
            static let personalizedANC: UInt16 = 16416 // 0x4020
            static let serialNumber: UInt16    = 16390 // 0x4006
            static let spatialAudio: UInt16    = 16463 // 0x404F
        }
    }

    struct BluetoothRequest {

        let command: UInt16
        let payload: [UInt8]
        let operationID: UInt8

        static let headerPrefix: [UInt8] = [0x55, 0x60, 0x01]
        static let headerSize = 8
    }

    struct BluetoothResponse {

        let command: UInt16
        let payload: [UInt8]
        let operationID: UInt8

        /// Nothing format: 55 60 01 [CMD_L] [CMD_H] [LEN] 00 [OP_ID] [PAYLOAD] [CRC_L](optional) [CRC_H](optional)
        init?(data: [UInt8]) {
            guard
                data.count >= 8, // at least header fields without payload
                data[0] == 0x55 // verify first header byte
            else {
                return nil
            }

            let payloadLength = Int(data[5])
            // Determine if CRC bytes are present
            let withCRC = (data.count >= 8 + payloadLength + 2)

            // Total bytes needed for a valid packet
            let requiredLength = 8 + payloadLength + (withCRC ? 2 : 0)
            guard data.count >= requiredLength else {
                return nil
            }

            // Extract command (little-endian)
            let cmdBytes = Data([data[3], data[4]])
            self.command = cmdBytes.withUnsafeBytes { $0.load(as: UInt16.self) }

            // Extract operation ID and payload
            self.operationID = data[7]
            self.payload = Array(data[8..<(8 + payloadLength)])

            // If CRC is present, verify it
            if withCRC {
                let crcIndex = 8 + payloadLength
                // Read CRC low and high bytes (little-endian)
                let receivedCRC = UInt16(data[crcIndex]) | (UInt16(data[crcIndex + 1]) << 8)

                // Calculate CRC over header + command + length + reserved + opID + payload
                let calculatedCRC = CRC16.calculate(
                    data: Array(data[0..<crcIndex])
                )

                // Fail init if CRC does not match
                guard receivedCRC == calculatedCRC else {
                    return nil
                }
            }
        }
    }

    struct CRC16 {

        static func calculate(data: [UInt8]) -> UInt16 {
            var crc: UInt16 = 0xFFFF

            for byte in data {
                crc ^= UInt16(byte)
                for _ in 0..<8 {
                    if (crc & 1) != 0 {
                        crc = (crc >> 1) ^ 0xA001
                    } else {
                        crc = crc >> 1
                    }
                }
            }

            return crc
        }
    }

    struct Gesture {
        let type: GestureType
        let action: GestureAction
        let device: GestureDevice?
    }
}

// MARK: Service UUID

extension NothingEar.ServiceUUID {

    static let ear = Self(
        uuid: CBUUID(string: "AEAC4A03-DFF5-498F-843A-34487CF133EB"),
        writeCharacteristicUUID: CBUUID(string: "AEAC4A03-DFF5-498F-843A-34487CF133EB"),
        notifyCharacteristicUUID: CBUUID(string: "AEAC4A03-DFF5-498F-843A-34487CF133EB")
    )

    static let headphone = Self(
        uuid: CBUUID(string: "FD90"),
        writeCharacteristicUUID: CBUUID(string: "68745353-1810-4B13-83A2-C1B21B652C9B"),
        notifyCharacteristicUUID: CBUUID(string: "CA235943-1810-45E6-8326-FC8CA3BC45CE")
    )

    static let all = [ear, headphone]

    static func get(for model: NothingEar.Model) -> Self {
        switch model {
            case .headphone1:
                return headphone
            default:
                return ear
        }
    }
}

// MARK: Bluetooth Request

extension NothingEar.BluetoothRequest {

    func toBytes() -> [UInt8] {
        var header = Self.headerPrefix

        // Add command bytes (little endian)
        let commandBytes = withUnsafeBytes(of: command.littleEndian) { Array($0) }
        header.append(commandBytes[0])
        header.append(commandBytes[1])

        // Add payload length
        header.append(UInt8(payload.count))

        // Add reserved byte
        header.append(0x00)

        // Add operation ID
        header.append(operationID)

        // Add payload
        header.append(contentsOf: payload)

        // Calculate and add CRC16
        let crc = NothingEar.CRC16.calculate(data: header)
        header.append(UInt8(crc & 0xFF))
        header.append(UInt8(crc >> 8))

        return header
    }
}

// MARK: Bluetooth Request

extension NothingEar.BluetoothRequest {

    static func setANCMode(
        _ mode: NothingEar.ANCMode,
        operationID: UInt8
    ) -> Self {
        let payload: [UInt8] = [0x01, mode.rawValue8, 0x00]
        return Self(
            command: NothingEar.BluetoothCommand.RequestWrite.anc,
            payload: payload,
            operationID: operationID
        )
    }

    static func setEnhancedBass(
        _ settings: NothingEar.EnhancedBassSettings,
        operationID: UInt8
    ) -> Self {
        let payload: [UInt8] = [
            settings.isEnabled ? 0x01: 0x00,
            UInt8(settings.level * 2)
        ]
        return Self(
            command: NothingEar.BluetoothCommand.RequestWrite.enhancedBass,
            payload: payload,
            operationID: operationID
        )
    }

    static func setEQPreset(
        _ preset: NothingEar.EQPreset,
        operationID: UInt8
    ) -> Self {
        let payload: [UInt8] = [preset.rawValue8, 0x00]
        return Self(
            command: NothingEar.BluetoothCommand.RequestWrite.eq,
            payload: payload,
            operationID: operationID
        )
    }

    static func setGesture(
        _ gesture: NothingEar.Gesture,
        operationID: UInt8
    ) -> Self {
        let deviceValue = gesture.device?.rawValue8 ?? 0x01
        let payload: [UInt8] = [0x01, deviceValue, 0x01, gesture.type.rawValue8, gesture.action.rawValue8]
        return Self(
            command: NothingEar.BluetoothCommand.RequestWrite.gesture,
            payload: payload,
            operationID: operationID
        )
    }

    // MARK: Device Settings

    static func setInEarDetection(
        _ isEnabled: Bool,
        operationID: UInt8
    ) -> Self {
        let payload: [UInt8] = [0x01, 0x01, isEnabled ? 0x01 : 0x00]
        return Self(
            command: NothingEar.BluetoothCommand.RequestWrite.inEarDetection,
            payload: payload,
            operationID: operationID
        )
    }

    static func setLowLatency(
        _ isEnabled: Bool,
        operationID: UInt8
    ) -> Self {
        let payload: [UInt8] = [isEnabled ? 0x01 : 0x02, 0x00]
        return Self(
            command: NothingEar.BluetoothCommand.RequestWrite.lowLatency,
            payload: payload,
            operationID: operationID
        )
    }

    static func setSpatialAudioMode(
        _ mode: NothingEar.SpatialAudioMode,
        operationID: UInt8
    ) -> Self {
        let (firstByte, secondByte) = mode.rawValue8
        let payload: [UInt8] = [firstByte, secondByte]
        
        return Self(
            command: NothingEar.BluetoothCommand.RequestWrite.spatialAudio,
            payload: payload,
            operationID: operationID
        )
    }
}

// MARK: Bluetooth Response

extension NothingEar.BluetoothResponse {

    func parseBattery(model: NothingEar.Model) -> NothingEar.Battery? {
        guard payload.count >= 1 else {
            return nil
        }

        switch model {
        case .headphone1:
            // Expect exactly 3 bytes: [header, ?, batteryData]
            guard payload.count == 3 else {
                return nil
            }

            let raw = payload[2]
            let level = Int(raw & 0x7F) // lower 7 bits: battery level
            let isCharging = (raw & 0x80) != 0 // MSB: charging flag
            let isConnected = level > 0 // consider connected if level > 0

            return .single(
                .init(
                    level: level,
                    isCharging: isCharging,
                    isConnected: isConnected
                )
            )

        default:
            // payload[0] = number of connected devices
            let connectedDevices = Int(payload[0])
            let expectedCount = 1 + (connectedDevices * 2)

            guard payload.count >= expectedCount else {
                return nil
            }

            var devices: [UInt8: NothingEar.BatteryLevel] = [:]

            for i in 0..<connectedDevices {
                let deviceId = payload[1 + (i * 2)]
                let raw = payload[2 + (i * 2)]
                let level = Int(raw & 0x7F) // lower 7 bits: battery level
                let isCharging = (raw & 0x80) != 0 // MSB: charging flag
                devices[deviceId] = .init(
                    level: level,
                    isCharging: isCharging,
                    isConnected: true
                )
            }

            return .budsWithCase(
                case: devices[0x04] ?? .disconnected,
                leftBud: devices[0x02] ?? .disconnected,
                rightBud: devices[0x03] ?? .disconnected
            )
        }
    }

    func parseANCMode() -> NothingEar.ANCMode? {
        guard payload.count >= 2 else {
            return nil
        }

        return .from8BitValue(payload[1])
    }

    func parseEQPreset() -> NothingEar.EQPreset? {
        if payload.count > 1 {
            return .from8BitValue(payload[1])
        } else if payload.count == 1 {
            return .from8BitValue(payload[0])
        } else {
            return nil
        }
    }

    func parseGestures() -> [NothingEar.Gesture] {
        guard payload.count >= 1 else {
            return []
        }

        let gestureCount = Int(payload[0])

        guard payload.count >= 1 + (gestureCount * 4) else {
            return []
        }

        var gestures: [NothingEar.Gesture] = []

        for i in 0..<gestureCount {
            let offset = 1 + (i * 4)
            guard
                let device = NothingEar.GestureDevice.from8BitValue(payload[offset]),
                let type = NothingEar.GestureType.from8BitValue(payload[offset + 2]),
                let action = NothingEar.GestureAction.from8BitValue(payload[offset + 3])
            else {
                continue
            }

            gestures.append(.init(type: type, action: action, device: device))
        }

        return gestures
    }

    // MARK: Device Info

    func parseFirmwareVersion() -> String {
        return String(bytes: payload, encoding: .utf8) ?? ""
    }

    func parseSerialNumber() -> String? {
        guard payload.count >= 7 else {
            return nil
        }

        // Skip first byte (E) and next 6 bytes (s02)
        let configData = Array(payload[7...])

        guard let configText = String(bytes: configData, encoding: .utf8) else {
            return nil
        }

        // Split by lines and parse configurations
        let lines = configText.components(separatedBy: "\n")

        for line in lines {
            let parts = line.components(separatedBy: ",")

            guard
                parts.count == 3,
                let _ = Int(parts[0]),
                let type = Int(parts[1])
            else {
                continue
            }

            let value = parts[2]

            // Look for type 4 (serial number) with non-empty value
            if type == 4 && !value.isEmpty {
                return value
            }
        }

        return nil
    }

    // MARK: Device Settings

    func parseInEarDetection() -> Bool? {
        guard payload.count >= 3 else {
            return nil
        }

        return payload[2] != 0
    }

    func parseLowLatency() -> Bool? {
        guard payload.count >= 1 else {
            return nil
        }

        return payload[0] == 1
    }

    func parseEnhancedBassSettings() -> NothingEar.EnhancedBassSettings? {
        guard payload.count >= 2 else {
            return nil
        }

        let enabled = payload[0] != 0
        let level = Int(payload[1]) / 2 // Convert from 0-200 to 0-100

        return .init(isEnabled: enabled, level: level)
    }

    func parseSpatialAudioMode() -> NothingEar.SpatialAudioMode? {
        guard payload.count >= 2 else {
            return nil
        }

        let firstByte = payload[0]
        let secondByte = payload[1]

        switch (firstByte, secondByte) {
            case (0x00, 0x00): return .off
            case (0x01, 0x00): return .fixed
            case (0x01, 0x01): return .headTracking
            default: return nil
        }
    }
}

// MARK: Active Noise Cancellation Mode - Bytes

extension NothingEar.ANCMode {

    var rawValue8: UInt8 {
        switch self {
            case .off: return 0x05
            case .transparent: return 0x07
            case .noiseCancellation(.low): return 0x03
            case .noiseCancellation(.mid): return 0x02
            case .noiseCancellation(.high): return 0x01
            case .noiseCancellation(.adaptive): return 0x04
        }
    }

    static func from8BitValue(_ value: UInt8) -> Self? {
        switch value {
            case 0x05: return .off
            case 0x07: return .transparent
            case 0x01: return .noiseCancellation(.high)
            case 0x02: return .noiseCancellation(.mid)
            case 0x03: return .noiseCancellation(.low)
            case 0x04: return .noiseCancellation(.adaptive)
            default: return nil
        }
    }
}

// MARK: Spatial Audio Mode - Bytes

extension NothingEar.SpatialAudioMode {

    var rawValue8: (UInt8, UInt8) {
        switch self {
            case .off: return (0x00, 0x00)
            case .fixed: return (0x01, 0x00)
            case .headTracking: return (0x01, 0x01)
        }
    }

    static func from8BitValues(_ firstByte: UInt8, _ secondByte: UInt8) -> Self? {
        switch (firstByte, secondByte) {
            case (0x00, 0x00): return .off
            case (0x01, 0x00): return .fixed
            case (0x01, 0x01): return .headTracking
            default: return nil
        }
    }
}

// MARK: Equalizer Preset - Bytes

extension NothingEar.EQPreset {

    var rawValue8: UInt8 {
        switch self {
            case .balanced: return 0x00
            case .voice: return 0x01
            case .moreTreble: return 0x02
            case .moreBass: return 0x03
            case .custom: return 0x05
            case .advanced: return 0x06
        }
    }

    static func from8BitValue(_ value: UInt8) -> Self? {
        switch value {
            case 0x00: return .balanced
            case 0x01: return .voice
            case 0x02: return .moreTreble
            case 0x03: return .moreBass
            case 0x05: return .custom // TODO: To parse custom settings
            case 0x06: return .advanced
            default: return nil
        }
    }
}

// MARK: Gesture Device - Bytes

extension NothingEar.GestureDevice {

    var rawValue8: UInt8 {
        switch self {
            case .left: return 0x02
            case .right: return 0x03
        }
    }

    static func from8BitValue(_ value: UInt8) -> Self? {
        switch value {
            case 0x02: return .left
            case 0x03: return .right
            default: return nil
        }
    }
}

// MARK: Gesture Type - Bytes

extension NothingEar.GestureType {

    var rawValue8: UInt8 {
        switch self {
            case .tap: return 0x01
            case .doubleTap: return 0x02
            case .trippleTap: return 0x03
            case .longPress: return 0x0B
        }
    }

    static func from8BitValue(_ value: UInt8) -> Self? {
        switch value {
            case 0x01: return .tap
            case 0x02: return .doubleTap
            case 0x03: return .trippleTap
            case 0x0B: return .longPress
            default: return nil
        }
    }
}

// MARK: Gesture Action - Bytes

extension NothingEar.GestureAction {

    var rawValue8: UInt8 {
        switch self {
            case .none: return 0x00
            case .playPause: return 0x01
            case .nextTrack: return 0x02
            case .previousTrack: return 0x03
            case .volumeUp: return 0x04
            case .volumeDown: return 0x05
            case .voiceAssistant: return 0x06
            case .ancToggle: return 0x07
            case .customAction: return 0x08
        }
    }

    static func from8BitValue(_ value: UInt8) -> Self? {
        switch value {
            case 0x00: return Self.none
            case 0x01: return .playPause
            case 0x02: return .nextTrack
            case 0x03: return .previousTrack
            case 0x04: return .volumeUp
            case 0x05: return .volumeDown
            case 0x06: return .voiceAssistant
            case 0x07: return .ancToggle
            case 0x08: return .customAction
            default: return nil
        }
    }
}
