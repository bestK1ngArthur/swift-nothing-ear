import XCTest
@testable import SwiftNothingEar

final class NothingEarTests: XCTestCase {

    // MARK: - Model Tests

    func testNothingEarModelProperties() {
        // Test ANC support
        XCTAssertTrue(NothingEar.Model.ear1(.white).supportsANC)
        XCTAssertTrue(NothingEar.Model.ear2(.white).supportsANC)
        XCTAssertTrue(NothingEar.Model.ear3(.white).supportsANC)
        XCTAssertFalse(NothingEar.Model.earStick.supportsANC)
        XCTAssertFalse(NothingEar.Model.earOpen.supportsANC)

        // Test Custom EQ support
        XCTAssertTrue(NothingEar.Model.ear1(.white).supportsCustomEQ)
        XCTAssertTrue(NothingEar.Model.ear2(.white).supportsCustomEQ)
        XCTAssertTrue(NothingEar.Model.ear3(.white).supportsCustomEQ)
        XCTAssertFalse(NothingEar.Model.earStick.supportsCustomEQ)

        // Test Enhanced Bass support
        XCTAssertTrue(NothingEar.Model.ear(.white).supportsEnhancedBass)
        XCTAssertTrue(NothingEar.Model.cmfBudsPro2(.white).supportsEnhancedBass)
        XCTAssertFalse(NothingEar.Model.ear1(.white).supportsEnhancedBass)
        XCTAssertFalse(NothingEar.Model.ear2(.white).supportsEnhancedBass)
        XCTAssertFalse(NothingEar.Model.ear3(.white).supportsEnhancedBass)

        // Test display names
        XCTAssertEqual(NothingEar.Model.ear1(.white).displayName, "Nothing Ear (1)")
        XCTAssertEqual(NothingEar.Model.ear2(.white).displayName, "Nothing Ear (2)")
        XCTAssertEqual(NothingEar.Model.ear3(.white).displayName, "Nothing Ear (3)")
        XCTAssertEqual(NothingEar.Model.cmfBudsPro(.white).displayName, "CMF Buds Pro")
    }

    func testEar3SerialNumberDetection() {
        // Test real serial number for white ear3
        let whiteEar3Serial = "SH10252535010003"
        let detectedModel = NothingEar.Model.getModel(fromSerialNumber: whiteEar3Serial)

        XCTAssertNotNil(detectedModel)
        if case .ear3(let color) = detectedModel {
            XCTAssertEqual(color, .white)
        } else {
            XCTFail("Expected ear3(.white) but got \(String(describing: detectedModel))")
        }

        // Test hypothetical black ear3 serial
        let blackEar3Serial = "SH10262635010003"
        let detectedBlackModel = NothingEar.Model.getModel(fromSerialNumber: blackEar3Serial)

        XCTAssertNotNil(detectedBlackModel)
        if case .ear3(let color) = detectedBlackModel {
            XCTAssertEqual(color, .black)
        } else {
            XCTFail("Expected ear3(.black) but got \(String(describing: detectedBlackModel))")
        }
    }

    func testBatteryStatus() {
        let leftBattery = NothingEar.BatteryLevel(level: 85, isCharging: false, isConnected: true)
        let rightBattery = NothingEar.BatteryLevel(level: 90, isCharging: true, isConnected: true)
        let caseBattery = NothingEar.BatteryLevel(level: 45, isCharging: false, isConnected: true)

        let batteryStatus = NothingEar.Battery.budsWithCase(case: caseBattery, leftBud: leftBattery, rightBud: rightBattery)

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
        let disconnected = NothingEar.BatteryLevel.disconnected
        XCTAssertEqual(disconnected.level, 0)
        XCTAssertFalse(disconnected.isCharging)
        XCTAssertFalse(disconnected.isConnected)
    }

    func testANCModeMapping() {
        // Test display names
        XCTAssertEqual(NothingEar.ANCMode.off.displayName, "Off")
        XCTAssertEqual(NothingEar.ANCMode.transparent.displayName, "Transparency")
        XCTAssertEqual(NothingEar.ANCMode.noiseCancellation(.high).displayName, "Noise Cancellation")

        // Test raw value conversion
        XCTAssertEqual(NothingEar.ANCMode.off.rawValue8, 0x05)
        XCTAssertEqual(NothingEar.ANCMode.transparent.rawValue8, 0x07)
        XCTAssertEqual(NothingEar.ANCMode.noiseCancellation(.high).rawValue8, 0x01)

        // Test reverse conversion
        XCTAssertEqual(NothingEar.ANCMode.from8BitValue(0x05), .off)
        XCTAssertEqual(NothingEar.ANCMode.from8BitValue(0x07), .transparent)
        XCTAssertEqual(NothingEar.ANCMode.from8BitValue(0x01), .noiseCancellation(.high))
        XCTAssertNil(NothingEar.ANCMode.from8BitValue(0xFF))
    }

    func testEQPreset() {
        XCTAssertEqual(NothingEar.EQPreset.balanced.displayName, "Balanced")
        XCTAssertEqual(NothingEar.EQPreset.voice.displayName, "Voice")
        XCTAssertEqual(NothingEar.EQPreset.custom.displayName, "Custom")
        XCTAssertEqual(NothingEar.EQPreset.moreBass.displayName, "More Bass")

        XCTAssertEqual(NothingEar.EQPreset.balanced.rawValue8, 0x00)
        XCTAssertEqual(NothingEar.EQPreset.voice.rawValue8, 0x01)
        XCTAssertEqual(NothingEar.EQPreset.custom.rawValue8, 0x05)
        XCTAssertEqual(NothingEar.EQPreset.moreBass.rawValue8, 0x03)
    }

    func testCustomEQSettings() {
        let customEQ = NothingEar.EQPresetCustom(lowFrequency: -2.5, midFrequency: 1.0, highFrequency: 3.2)

        XCTAssertEqual(customEQ.lowFrequency, -2.5)
        XCTAssertEqual(customEQ.midFrequency, 1.0)
        XCTAssertEqual(customEQ.highFrequency, 3.2)
    }

    func testGestureMapping() {
        let gesture = NothingEar.Gesture(type: .doubleTap, action: .playPause, device: .left)

        XCTAssertEqual(gesture.device, .left)
        XCTAssertEqual(gesture.type, .doubleTap)
        XCTAssertEqual(gesture.action, .playPause)

        XCTAssertEqual(NothingEar.GestureDevice.left.rawValue8, 0x02)
        XCTAssertEqual(NothingEar.GestureDevice.right.rawValue8, 0x03)

        XCTAssertEqual(NothingEar.GestureType.tap.rawValue8, 0x01)
        XCTAssertEqual(NothingEar.GestureType.doubleTap.rawValue8, 0x02)
        XCTAssertEqual(NothingEar.GestureType.longPress.rawValue8, 0x0B)

        XCTAssertEqual(NothingEar.GestureAction.playPause.rawValue8, 0x01)
        XCTAssertEqual(NothingEar.GestureAction.nextTrack.rawValue8, 0x02)
        XCTAssertEqual(NothingEar.GestureAction.voiceAssistant.rawValue8, 0x06)
    }

    func testDeviceSettings() {
        var settings = NothingEar.DeviceSettings.default
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
        let bass1 = NothingEar.EnhancedBassSettings(isEnabled: true, level: 50)
        XCTAssertTrue(bass1.isEnabled)
        XCTAssertEqual(bass1.level, 50)

        // Test different settings
        let bass2 = NothingEar.EnhancedBassSettings(isEnabled: false, level: 100)
        XCTAssertFalse(bass2.isEnabled)
        XCTAssertEqual(bass2.level, 100)

        let bass3 = NothingEar.EnhancedBassSettings(isEnabled: true, level: 0)
        XCTAssertTrue(bass3.isEnabled)
        XCTAssertEqual(bass3.level, 0)
    }

    // MARK: - Protocol Tests

    func testCRC16Calculation() {
        let testData: [UInt8] = [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x01]
        let crc = NothingEar.CRC16.calculate(data: testData)

        // CRC should be deterministic for the same input
        let crc2 = NothingEar.CRC16.calculate(data: testData)
        XCTAssertEqual(crc, crc2)

        // Different data should produce different CRC
        let differentData: [UInt8] = [0x55, 0x60, 0x01, 0x07, 0xC1, 0x00, 0x00, 0x01]
        let differentCRC = NothingEar.CRC16.calculate(data: differentData)
        XCTAssertNotEqual(crc, differentCRC)
    }

    func testBluetoothRequestCreation() {
        let request = NothingEar.BluetoothRequest(command: 0xC007, payload: [], operationID: 1)
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
        let batteryResponse = NothingEar.BluetoothResponse(data: [0x55, 0x60, 0x01, 0x01, 0xE0, 0x05, 0x00, 0x01, 0x02, 0x02, 0x55, 0x03, 0x47])
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
        let ancResponse = NothingEar.BluetoothResponse(data: [0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01, 0x01, 0x05])
        XCTAssertNotNil(ancResponse)
        if let response = ancResponse {
            let ancMode = response.parseANCMode()
            XCTAssertEqual(ancMode, .off)
        }

        // Test EQ response parsing
        let eqResponse = NothingEar.BluetoothResponse(data: [0x55, 0x60, 0x01, 0x1F, 0x40, 0x01, 0x00, 0x01, 0x03])
        XCTAssertNotNil(eqResponse)
        if let response = eqResponse {
            let eqPreset = response.parseEQPreset()
            XCTAssertEqual(eqPreset, .moreBass)
        }

        // Test firmware parsing
        let firmwareData = Array("1.2.3".utf8)
        let firmwareResponse = NothingEar.BluetoothResponse(data: [0x55, 0x60, 0x01, 0x42, 0x40, UInt8(firmwareData.count), 0x00, 0x01] + firmwareData)
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
        let correctCRC = NothingEar.CRC16.calculate(data: dataWithoutCRC)
        dataWithoutCRC.append(UInt8(correctCRC & 0xFF))
        dataWithoutCRC.append(UInt8(correctCRC >> 8))

        let response = NothingEar.BluetoothResponse(data: dataWithoutCRC)
        XCTAssertNotNil(response)
        XCTAssertEqual(response?.command, 0xC007)
        XCTAssertEqual(response?.operationID, 1)
        XCTAssertEqual(response?.payload, [0x85, 0x90])
    }

    // MARK: - Error Tests

    func testConnectionErrors() {
        XCTAssertEqual(NothingEar.ConnectionError.bluetooth(.unavailable).errorDescription,
                      "Bluetooth is not available on this device")
        XCTAssertEqual(NothingEar.ConnectionError.deviceNotFound.errorDescription,
                      "Nothing device is not found")
        XCTAssertEqual(NothingEar.ConnectionError.connectionFailed.errorDescription,
                      "Failed to connect to device")
        XCTAssertEqual(NothingEar.ConnectionError.invalidResponse.errorDescription,
                      "Received invalid response from device")
        XCTAssertEqual(NothingEar.ConnectionError.unsupportedOperation.errorDescription,
                      "Operation not supported by this device model")
        XCTAssertEqual(NothingEar.ConnectionError.timeout.errorDescription,
                      "Operation timed out")
    }

    // MARK: - Integration Tests

    @MainActor
    func testDeviceFeatureSupport() {
        // Create a minimal callback implementation for testing
        let callback = NothingEar.Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onError: { _ in }
        )

        let device = NothingEar.Device(callback)

        // Without device info, device should not be connected
        XCTAssertFalse(device.isConnected)
        XCTAssertEqual(device.connectionStatus, .disconnected)

        // Test with mock device info would require more complex setup
        // This is a basic structure test
    }

    // MARK: - Already Connected Devices Tests

    @MainActor
    func testDeviceConnectionHandling() {
        let callback = NothingEar.Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onError: { _ in }
        )

        let device = NothingEar.Device(callback)

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
        let foundConnectedState = NothingEar.ConnectionStatus.foundConnected
        let connectedState = NothingEar.ConnectionStatus.connected
        let disconnectedState = NothingEar.ConnectionStatus.disconnected
        let scanningState = NothingEar.ConnectionStatus.scanning
        let connectingState = NothingEar.ConnectionStatus.connecting

        // All states should be different
        XCTAssertNotEqual(foundConnectedState, connectedState)
        XCTAssertNotEqual(foundConnectedState, disconnectedState)
        XCTAssertNotEqual(foundConnectedState, scanningState)
        XCTAssertNotEqual(foundConnectedState, connectingState)
    }

    @MainActor
    func testDeviceBasicOperations() {
        let callback = NothingEar.Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onError: { _ in }
        )

        let device = NothingEar.Device(callback)

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
        let callback = NothingEar.Callback(
            onDiscover: { _ in },
            onConnect: { _ in },
            onDisconnect: { _ in },
            onUpdateBattery: { _ in },
            onUpdateANCMode: { _ in },
            onUpdateEnhancedBass: { _ in },
            onUpdateEQPreset: { _ in },
            onUpdateDeviceSettings: { _ in },
            onError: { _ in }
        )

        let device = NothingEar.Device(callback)

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
