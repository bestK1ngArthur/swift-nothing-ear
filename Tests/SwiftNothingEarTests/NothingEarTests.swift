import XCTest
@testable import SwiftNothingEar

final class NothingEarTests: XCTestCase {

    // MARK: - Model Tests

    func testNothingEarModelProperties() {
        // Test ANC support
        XCTAssertTrue(Model.ear1(.white).supportsANC)
        XCTAssertTrue(Model.ear2(.white).supportsANC)
        XCTAssertTrue(Model.ear3(.white).supportsANC)
        XCTAssertFalse(Model.earStick.supportsANC)
        XCTAssertFalse(Model.earOpen.supportsANC)

        // Test Custom EQ support
        XCTAssertTrue(Model.ear1(.white).supportsCustomEQ)
        XCTAssertTrue(Model.ear2(.white).supportsCustomEQ)
        XCTAssertTrue(Model.ear3(.white).supportsCustomEQ)
        XCTAssertFalse(Model.earStick.supportsCustomEQ)

        // Test Enhanced Bass support
        XCTAssertTrue(Model.ear(.white).supportsEnhancedBass)
        XCTAssertTrue(Model.cmfBudsPro2(.white).supportsEnhancedBass)
        XCTAssertTrue(Model.cmfBuds2(.darkGrey).supportsEnhancedBass)
        XCTAssertFalse(Model.ear1(.white).supportsEnhancedBass)
        XCTAssertFalse(Model.ear2(.white).supportsEnhancedBass)
        XCTAssertFalse(Model.ear3(.white).supportsEnhancedBass)

        // Test display names
        XCTAssertEqual(Model.ear1(.white).displayName, "Nothing Ear (1)")
        XCTAssertEqual(Model.ear2(.white).displayName, "Nothing Ear (2)")
        XCTAssertEqual(Model.ear3(.white).displayName, "Nothing Ear (3)")
        XCTAssertEqual(Model.cmfBudsPro(.white).displayName, "CMF Buds Pro")
        XCTAssertEqual(Model.cmfBuds2(.darkGrey).displayName, "CMF Buds 2")
    }

    func testEar3SerialNumberDetection() {
        // Test real serial number for white ear3
        let whiteEar3Serial = "SH10252535010003"
        let detectedModel = Model.getModel(from: whiteEar3Serial)

        XCTAssertNotNil(detectedModel)
        if case .ear3(let color) = detectedModel {
            XCTAssertEqual(color, .white)
        } else {
            XCTFail("Expected ear3(.white) but got \(String(describing: detectedModel))")
        }

        // Test hypothetical black ear3 serial
        let blackEar3Serial = "SH10262635010003"
        let detectedBlackModel = Model.getModel(from: blackEar3Serial)

        XCTAssertNotNil(detectedBlackModel)
        if case .ear3(let color) = detectedBlackModel {
            XCTAssertEqual(color, .black)
        } else {
            XCTFail("Expected ear3(.black) but got \(String(describing: detectedBlackModel))")
        }
    }

    func testBatteryStatus() {
        let leftBattery = BatteryLevel(level: 85, isCharging: false, isConnected: true)
        let rightBattery = BatteryLevel(level: 90, isCharging: true, isConnected: true)
        let caseBattery = BatteryLevel(level: 45, isCharging: false, isConnected: true)

        let batteryStatus = Battery.budsWithCase(case: caseBattery, leftBud: leftBattery, rightBud: rightBattery)

        // Test budsWithCase battery type
        if case .budsWithCase(let caseBat, let leftBud, let rightBud) = batteryStatus {
            XCTAssertEqual(leftBud.level, 85)
            XCTAssertFalse(leftBud.isCharging)
            XCTAssertEqual(rightBud.level, 90)
            XCTAssertTrue(rightBud.isCharging)
            XCTAssertEqual(caseBat.level, 45)
        } else {
            XCTFail("Expected budsWithCase battery type")
        }

        // Test disconnected battery
        let disconnected = BatteryLevel.disconnected
        XCTAssertEqual(disconnected.level, 0)
        XCTAssertFalse(disconnected.isCharging)
        XCTAssertFalse(disconnected.isConnected)
    }

    func testANCModeMapping() {
        // Test display names
        XCTAssertEqual(ANCMode.off.displayName, "Off")
        XCTAssertEqual(ANCMode.transparent.displayName, "Transparency")
        XCTAssertEqual(ANCMode.noiseCancellation(.high).displayName, "Noise Cancellation")

        // Test raw value conversion
        XCTAssertEqual(ANCMode.off.rawValue8, 0x05)
        XCTAssertEqual(ANCMode.transparent.rawValue8, 0x07)
        XCTAssertEqual(ANCMode.noiseCancellation(.high).rawValue8, 0x01)

        // Test reverse conversion
        XCTAssertEqual(ANCMode.from8BitValue(0x05), .off)
        XCTAssertEqual(ANCMode.from8BitValue(0x07), .transparent)
        XCTAssertEqual(ANCMode.from8BitValue(0x01), .noiseCancellation(.high))
        XCTAssertNil(ANCMode.from8BitValue(0xFF))
    }

    func testEQPreset() {
        XCTAssertEqual(EQPreset.balanced.displayName, "Balanced")
        XCTAssertEqual(EQPreset.voice.displayName, "Voice")
        XCTAssertEqual(EQPreset.custom.displayName, "Custom")
        XCTAssertEqual(EQPreset.moreBass.displayName, "More Bass")

        XCTAssertEqual(EQPreset.balanced.rawValue8, 0x00)
        XCTAssertEqual(EQPreset.voice.rawValue8, 0x01)
        XCTAssertEqual(EQPreset.custom.rawValue8, 0x05)
        XCTAssertEqual(EQPreset.moreBass.rawValue8, 0x03)
    }

    func testCustomEQSettings() {
        let customEQ = EQPresetCustom(lowFrequency: -2.5, midFrequency: 1.0, highFrequency: 3.2)

        XCTAssertEqual(customEQ.lowFrequency, -2.5)
        XCTAssertEqual(customEQ.midFrequency, 1.0)
        XCTAssertEqual(customEQ.highFrequency, 3.2)
    }

    func testGestureMapping() {
        let gesture = Gesture(type: .doubleTap, action: .playPause, device: .left)

        XCTAssertEqual(gesture.device, .left)
        XCTAssertEqual(gesture.type, .doubleTap)
        XCTAssertEqual(gesture.action, .playPause)

        XCTAssertEqual(GestureDevice.left.rawValue8, 0x02)
        XCTAssertEqual(GestureDevice.right.rawValue8, 0x03)

        XCTAssertEqual(GestureType.tap.rawValue8, 0x01)
        XCTAssertEqual(GestureType.doubleTap.rawValue8, 0x02)
        XCTAssertEqual(GestureType.longPress.rawValue8, 0x0B)

        XCTAssertEqual(GestureAction.playPause.rawValue8, 0x01)
        XCTAssertEqual(GestureAction.nextTrack.rawValue8, 0x02)
        XCTAssertEqual(GestureAction.voiceAssistant.rawValue8, 0x06)
    }

    func testDeviceSettings() {
        var settings = DeviceSettings.default
        XCTAssertFalse(settings.inEarDetection) // Default false
        XCTAssertFalse(settings.lowLatency) // Default false
        XCTAssertFalse(settings.personalizedANC) // Default false

        // Update settings
        settings.inEarDetection = true
        settings.lowLatency = true

        XCTAssertTrue(settings.inEarDetection)
        XCTAssertTrue(settings.lowLatency)
    }

    func testEnhancedBassSettings() {
        let bass1 = EnhancedBassSettings(isEnabled: true, level: 50)
        XCTAssertTrue(bass1.isEnabled)
        XCTAssertEqual(bass1.level, 50)

        // Test different settings
        let bass2 = EnhancedBassSettings(isEnabled: false, level: 100)
        XCTAssertFalse(bass2.isEnabled)
        XCTAssertEqual(bass2.level, 100)

        let bass3 = EnhancedBassSettings(isEnabled: true, level: 0)
        XCTAssertTrue(bass3.isEnabled)
        XCTAssertEqual(bass3.level, 0)
    }

    func testSerialNumberParsingHandlesLegacyAndNewPayloads() {
        let expectedCMFSerial = "123456789"

        let cmfBasePayload: [UInt8] = [
            0x06, 0x32, 0x2C, 0x32, 0x2C, 0x31, 0x2E, 0x30, 0x2E, 0x31, 0x2E, 0x35, 0x30, 0x0A, 0x0A,
            0x32, 0x2C, 0x34, 0x2C, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x0A, 0x32,
            0x2C, 0x36, 0x2C, 0x31, 0x45, 0x42, 0x34, 0x45, 0x33, 0x45, 0x44, 0x42, 0x30, 0x33, 0x43,
            0x0A, 0x33, 0x2C, 0x32, 0x2C, 0x31, 0x2E, 0x30, 0x2E, 0x31, 0x2E, 0x35, 0x30, 0x0A, 0x0A,
            0x33, 0x2C, 0x34, 0x2C, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x0A, 0x32,
            0x2C, 0x36, 0x2C, 0x31, 0x45, 0x42, 0x34, 0x45, 0x33, 0x45, 0x44, 0x42, 0x30, 0x33, 0x43,
            0x0A
        ]
        let cmfPayloadWithCRCA: [UInt8] = cmfBasePayload + [0x19, 0xE1]
        let cmfPayloadWithCRCB: [UInt8] = cmfBasePayload + [0xEF, 0xA4]

        func makeResponse(payload: [UInt8]) -> BluetoothResponse? {
            let command = BluetoothCommand.Response.serialNumber
            let data: [UInt8] = [
                0x55, 0x60, 0x01,
                UInt8(command & 0xFF),
                UInt8(command >> 8),
                UInt8(payload.count),
                0x00,
                0x01
            ] + payload

            return BluetoothResponse(data: data)
        }

        guard
            let baseResponse = makeResponse(payload: cmfBasePayload),
            let crcAResponse = makeResponse(payload: cmfPayloadWithCRCA),
            let crcBResponse = makeResponse(payload: cmfPayloadWithCRCB)
        else {
            XCTFail("Failed to build CMF serial number responses")
            return
        }

        XCTAssertEqual(baseResponse.parseSerialNumber(), expectedCMFSerial)
        XCTAssertEqual(crcAResponse.parseSerialNumber(), expectedCMFSerial)
        XCTAssertEqual(crcBResponse.parseSerialNumber(), expectedCMFSerial)

        let legacySerial = "LEGACY123456"
        let legacyNoise: [UInt8] = [0x01, 0x02, 0x00, 0x04, 0x05, 0x1F, 0x07]
        let legacyPayload = legacyNoise + Array("0,4,\(legacySerial)\n".utf8)
        guard let legacyResponse = makeResponse(payload: legacyPayload) else {
            XCTFail("Failed to build legacy serial number response")
            return
        }
        XCTAssertEqual(legacyResponse.parseSerialNumber(), legacySerial)
    }

    // MARK: - Protocol Tests

    func testCRC16Calculation() {
        let testData: [UInt8] = [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x01]
        let crc = CRC16.calculate(data: testData)

        // CRC should be deterministic for the same input
        let crc2 = CRC16.calculate(data: testData)
        XCTAssertEqual(crc, crc2)

        // Different data should produce different CRC
        let differentData: [UInt8] = [0x55, 0x60, 0x01, 0x07, 0xC1, 0x00, 0x00, 0x01]
        let differentCRC = CRC16.calculate(data: differentData)
        XCTAssertNotEqual(crc, differentCRC)
    }

    func testBluetoothRequestCreation() {
        let request = BluetoothRequest(command: 0xC007, payload: [], operationID: 1)
        let bytes = request.toBytes()

        // Check header
        XCTAssertEqual(bytes[0], 0x55)
        XCTAssertEqual(bytes[1], 0x60)
        XCTAssertEqual(bytes[2], 0x01)

        // Check command bytes (little endian)
        XCTAssertEqual(bytes[3], 0x07)
        XCTAssertEqual(bytes[4], 0xC0)

        // Check payload length
        XCTAssertEqual(bytes[5], 0x00)

        // Check operation ID
        XCTAssertEqual(bytes[7], 0x01)

        // Should have CRC at the end
        XCTAssertTrue(bytes.count >= 10) // 8 header + 2 CRC minimum
    }

    func testResponseParsing() {
        // Test battery response parsing
        let batteryResponse = BluetoothResponse(data: [0x55, 0x60, 0x01, 0x01, 0xE0, 0x05, 0x00, 0x01, 0x02, 0x02, 0x55, 0x03, 0x47])
        XCTAssertNotNil(batteryResponse)
        if let response = batteryResponse {
            let battery = response.parseBattery(model: .ear1(.white))
            XCTAssertNotNil(battery)
            if case .budsWithCase(_, let leftBud, let rightBud) = battery {
                XCTAssertEqual(leftBud.level, 85)
                XCTAssertFalse(leftBud.isCharging)
                XCTAssertEqual(rightBud.level, 71)
                XCTAssertFalse(rightBud.isCharging)
            }
        }

        // Test ANC response parsing
        let ancResponse = BluetoothResponse(data: [0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01, 0x01, 0x05])
        XCTAssertNotNil(ancResponse)
        if let response = ancResponse {
            let ancMode = response.parseANCMode()
            XCTAssertEqual(ancMode, .off)
        }

        // Test EQ response parsing
        let eqResponse = BluetoothResponse(data: [0x55, 0x60, 0x01, 0x1F, 0x40, 0x01, 0x00, 0x01, 0x03])
        XCTAssertNotNil(eqResponse)
        if let response = eqResponse {
            let eqPreset = response.parseEQPreset()
            XCTAssertEqual(eqPreset, .moreBass)
        }

        // Test firmware parsing
        let firmwareData = Array("1.2.3".utf8)
        let firmwareResponse = BluetoothResponse(data: [0x55, 0x60, 0x01, 0x42, 0x40, UInt8(firmwareData.count), 0x00, 0x01] + firmwareData)
        XCTAssertNotNil(firmwareResponse)
        if let response = firmwareResponse {
            let firmware = response.parseFirmwareVersion()
            XCTAssertEqual(firmware, "1.2.3")
        }
    }

    func testBluetoothResponse() {
        // Create a valid response packet
        let responseData: [UInt8] = [
            0x55, 0x60, 0x01, // Header prefix
            0x07, 0xC0,       // Command (little endian)
            0x02,             // Payload length
            0x00,             // Reserved
            0x01,             // Operation ID
            0x85, 0x90,       // Payload
            0x12, 0x34        // CRC (will be recalculated)
        ]

        // Calculate correct CRC
        var dataWithoutCRC = Array(responseData[0..<10])
        let correctCRC = CRC16.calculate(data: dataWithoutCRC)
        dataWithoutCRC.append(UInt8(correctCRC & 0xFF))
        dataWithoutCRC.append(UInt8(correctCRC >> 8))

        let response = BluetoothResponse(data: dataWithoutCRC)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.command, 0xC007)
        XCTAssertEqual(response?.operationID, 1)
        XCTAssertEqual(response?.payload, [0x85, 0x90])

        // CMF Buds Pro 2 packets calculate CRC by using the payload only.
        var payloadOnlyPacket: [UInt8] = [
            0x55, 0x60, 0x01, // Header
            0x06, 0x40,       // Command (serial number response)
            0x04,             // Payload length
            0x00,             // Reserved
            0x02              // Operation ID
        ]
        let payload: [UInt8] = [0x0C, 0x32, 0x2C, 0x31]
        payloadOnlyPacket.append(contentsOf: payload)

        let payloadCRC = CRC16.calculate(data: payload)
        payloadOnlyPacket.append(UInt8(payloadCRC & 0xFF))
        payloadOnlyPacket.append(UInt8(payloadCRC >> 8))

        let payloadOnlyResponse = BluetoothResponse(data: payloadOnlyPacket)
        XCTAssertNotNil(payloadOnlyResponse)
        XCTAssertEqual(payloadOnlyResponse?.command, 0x4006)
        XCTAssertEqual(payloadOnlyResponse?.operationID, 0x02)
        XCTAssertEqual(payloadOnlyResponse?.payload, payload)
    }

    // MARK: - Error Tests

    func testConnectionErrors() {
        XCTAssertEqual(ConnectionError.bluetooth(.unavailable).errorDescription,
                      "Bluetooth is not available on this device")
        XCTAssertEqual(ConnectionError.deviceNotFound.errorDescription,
                      "Nothing device is not found")
        XCTAssertEqual(ConnectionError.connectionFailed.errorDescription,
                      "Failed to connect to device")
        XCTAssertEqual(ConnectionError.invalidResponse.errorDescription,
                      "Received invalid response from device")
        XCTAssertEqual(ConnectionError.unsupportedOperation.errorDescription,
                      "Operation not supported by this device model")
        XCTAssertEqual(ConnectionError.timeout.errorDescription,
                      "Operation timed out")
    }

    // MARK: - Integration Tests

    @MainActor
    func testDeviceFeatureSupport() {
        // Create a minimal callback implementation for testing
        let callback = Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateSpatialAudio: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in },
            onError: { _ in }
        )

        let device = Device(callback)

        // Without device info, device should not be connected
        XCTAssertFalse(device.isConnected)
        XCTAssertEqual(device.connectionStatus, .disconnected)

        // Test with mock device info would require more complex setup
        // This is a basic structure test
    }

    // MARK: - Already Connected Devices Tests

    @MainActor
    func testDeviceConnectionHandling() {
        let callback = Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateSpatialAudio: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in },
            onError: { _ in }
        )

        let device = Device(callback)

        // Test initial state
        XCTAssertEqual(device.connectionStatus, .disconnected)
        XCTAssertFalse(device.isConnected)

        // Test that device can be started scanning (will fail due to no Bluetooth in tests)
        XCTAssertNoThrow(device.startScanning())

        // Test that device can be stopped scanning
        XCTAssertNoThrow(device.stopScanning())

        // Test that device can be disconnected even if not connected
        XCTAssertNoThrow(device.disconnect())
    }

    @MainActor
    func testConnectionStates() {
        // Test that foundConnected state exists and is different from others
        let foundConnectedState = ConnectionStatus.foundConnected
        let connectedState = ConnectionStatus.connected
        let disconnectedState = ConnectionStatus.disconnected
        let scanningState = ConnectionStatus.scanning
        let connectingState = ConnectionStatus.connecting

        // All states should be different
        XCTAssertNotEqual(foundConnectedState, connectedState)
        XCTAssertNotEqual(foundConnectedState, disconnectedState)
        XCTAssertNotEqual(foundConnectedState, scanningState)
        XCTAssertNotEqual(foundConnectedState, connectingState)
    }

    @MainActor
    func testDeviceBasicOperations() {
        let callback = Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateSpatialAudio: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in },
            onError: { _ in }
        )

        let device = Device(callback)

        // Should not crash when Bluetooth is unavailable
        let initialState = device.connectionStatus

        // Test basic operations don't crash
        XCTAssertNoThrow(device.startScanning())
        XCTAssertNoThrow(device.stopScanning())

        // State should remain disconnected since Bluetooth is unavailable in tests
        XCTAssertEqual(device.connectionStatus, initialState)
    }

    @MainActor
    func testDevicePublicAPI() {
        let callback = Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateSpatialAudio: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onUpdateRingBuds: { _ in },
            onError: { _ in }
        )

        let device = Device(callback)

        // Test that basic properties are accessible
        XCTAssertEqual(device.connectionStatus, .disconnected)
        XCTAssertFalse(device.isConnected)
        XCTAssertNil(device.deviceInfo)
        XCTAssertNil(device.battery)
        XCTAssertNil(device.ancMode)
        XCTAssertNil(device.enhancedBass)
        XCTAssertNil(device.eqPreset)
    }
}
