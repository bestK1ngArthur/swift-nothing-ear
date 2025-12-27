import XCTest
@testable import SwiftNothingEar

final class NothingEar2Tests: XCTestCase {

    func testBattery() {
        let model = DeviceModel.ear2(.black)

        let batteryRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.battery, payload: [], operationID: 0x01)
        XCTAssertEqual(batteryRequest.toBytes(), [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x01, 0xAC, 0xDF])

        let batteryResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x07, 0x40, 0x07, 0x00, 0x01,
            0x03, 0x04, 0x37, 0x02, 0xC6, 0x03, 0x41
        ]
        guard let batteryResponse = BluetoothResponse(data: batteryResponseBytes) else {
            XCTFail("Failed to parse battery response")
            return
        }
        if case .budsWithCase(let caseLevel, let left, let right) = batteryResponse.parseBattery(model: model) {
            XCTAssertEqual(caseLevel.level, 55)
            XCTAssertEqual(left.level, 70)
            XCTAssertEqual(right.level, 65)
        } else {
            XCTFail("Expected budsWithCase battery")
        }
    }

    func testANC() {
        let ancRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.anc, payload: [], operationID: 0x01)
        XCTAssertEqual(ancRequest.toBytes(), [0x55, 0x60, 0x01, 0x1E, 0xC0, 0x00, 0x00, 0x01, 0xB1, 0x1D])

        let ancResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01,
            0x00, 0x02
        ]
        guard let ancResponse = BluetoothResponse(data: ancResponseBytes) else {
            XCTFail("Failed to parse ANC response")
            return
        }
        XCTAssertEqual(ancResponse.parseANCMode(), .active(.mid))
    }

    func testSpatialAudio() {
        let spatialRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.spatialAudio, payload: [], operationID: 0x01)
        XCTAssertEqual(spatialRequest.toBytes(), [0x55, 0x60, 0x01, 0x4F, 0xC0, 0x00, 0x00, 0x01, 0x4C, 0xD1])

        let spatialResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x4F, 0x40, 0x02, 0x00, 0x01,
            0x01, 0x00
        ]
        guard let spatialResponse = BluetoothResponse(data: spatialResponseBytes) else {
            XCTFail("Failed to parse spatial audio response")
            return
        }
        XCTAssertEqual(spatialResponse.parseSpatialAudioMode(), .fixed)
    }

    func testEnhancedBass() {
        let enhancedBassRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.enhancedBass, payload: [], operationID: 0x01)
        XCTAssertEqual(enhancedBassRequest.toBytes(), [0x55, 0x60, 0x01, 0x4E, 0xC0, 0x00, 0x00, 0x01, 0x71, 0x11])

        let enhancedBassResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x4E, 0x40, 0x02, 0x00, 0x01,
            0x01, 0x3C
        ]
        guard let enhancedBassResponse = BluetoothResponse(data: enhancedBassResponseBytes) else {
            XCTFail("Failed to parse enhanced bass response")
            return
        }
        let enhancedBass = enhancedBassResponse.parseEnhancedBassSettings()
        XCTAssertEqual(enhancedBass?.isEnabled, true)
        XCTAssertEqual(enhancedBass?.level, 30)
    }

    func testEQPreset() {
        let eqRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.eq, payload: [], operationID: 0x01)
        XCTAssertEqual(eqRequest.toBytes(), [0x55, 0x60, 0x01, 0x1F, 0xC0, 0x00, 0x00, 0x01, 0x8C, 0xDD])

        let eqResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x1F, 0x40, 0x01, 0x00, 0x01,
            0x00
        ]
        guard let eqResponse = BluetoothResponse(data: eqResponseBytes) else {
            XCTFail("Failed to parse EQ response")
            return
        }
        XCTAssertEqual(eqResponse.parseEQPreset(), .balanced)
    }

    func testInEarDetection() {
        let inEarRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.inEarDetection, payload: [], operationID: 0x01)
        XCTAssertEqual(inEarRequest.toBytes(), [0x55, 0x60, 0x01, 0x0E, 0xC0, 0x00, 0x00, 0x01, 0x70, 0xDE])

        let inEarResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x0E, 0x40, 0x03, 0x00, 0x01,
            0x01, 0x01, 0x01
        ]
        guard let inEarResponse = BluetoothResponse(data: inEarResponseBytes) else {
            XCTFail("Failed to parse in-ear response")
            return
        }
        XCTAssertEqual(inEarResponse.parseInEarDetection(), true)
    }

    func testLowLatency() {
        let latencyRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.lowLatency, payload: [], operationID: 0x01)
        XCTAssertEqual(latencyRequest.toBytes(), [0x55, 0x60, 0x01, 0x41, 0xC0, 0x00, 0x00, 0x01, 0x25, 0x10])

        let latencyResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x41, 0x40, 0x01, 0x00, 0x01,
            0x00
        ]
        guard let latencyResponse = BluetoothResponse(data: latencyResponseBytes) else {
            XCTFail("Failed to parse low latency response")
            return
        }
        XCTAssertEqual(latencyResponse.parseLowLatency(), false)
    }

    func testGestures() {
        let gestureRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.gesture, payload: [], operationID: 0x01)
        XCTAssertEqual(gestureRequest.toBytes(), [0x55, 0x60, 0x01, 0x18, 0xC0, 0x00, 0x00, 0x01, 0x39, 0x1D])

        let gestureResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x18, 0x40, 0x05, 0x00, 0x01,
            0x01, 0x03, 0x00, 0x02, 0x02
        ]
        guard let gestureResponse = BluetoothResponse(data: gestureResponseBytes) else {
            XCTFail("Failed to parse gesture response")
            return
        }
        let gestures = gestureResponse.parseGestures()
        XCTAssertEqual(gestures.count, 1)
        XCTAssertEqual(gestures.first?.device, .right)
        XCTAssertEqual(gestures.first?.type, .doubleTap)
        XCTAssertEqual(gestures.first?.action, .nextTrack)
    }

    func testRingBuds() {
        let ringBudsRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.ringBuds, payload: [], operationID: 0x01)
        XCTAssertEqual(ringBudsRequest.toBytes(), [0x55, 0x60, 0x01, 0x02, 0xC0, 0x00, 0x00, 0x01, 0x60, 0xDF])

        let ringBudsResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x02, 0x40, 0x03, 0x00, 0x01,
            0x00, 0x03, 0x00
        ]
        guard let ringBudsResponse = BluetoothResponse(data: ringBudsResponseBytes) else {
            XCTFail("Failed to parse ring buds response")
            return
        }
        let ringBuds = ringBudsResponse.parseRingBuds()
        XCTAssertEqual(ringBuds?.bud, .right)
        XCTAssertEqual(ringBuds?.isOn, false)
    }
}
