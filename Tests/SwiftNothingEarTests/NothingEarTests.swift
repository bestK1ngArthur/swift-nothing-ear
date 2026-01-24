import XCTest
@testable import SwiftNothingEar

final class NothingEarTests: XCTestCase {

    func testBattery() {
        let model = DeviceModel.ear(.white)

        let batteryRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.battery, payload: [], operationID: 0x01)
        XCTAssertEqual(batteryRequest.toBytes(), [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x01, 0xAC, 0xDF])

        let batteryResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x07, 0x40, 0x07, 0x00, 0x01,
            0x03, 0x04, 0xB2, 0x02, 0x3C, 0x03, 0x3A
        ]
        guard let batteryResponse = BluetoothResponse(data: batteryResponseBytes) else {
            XCTFail("Failed to parse battery response")
            return
        }
        if case .budsWithCase(let caseLevel, let left, let right) = batteryResponse.parseBattery(model: model) {
            XCTAssertEqual(caseLevel.level, 50)
            XCTAssertEqual(left.level, 60)
            XCTAssertEqual(right.level, 58)
        } else {
            XCTFail("Expected budsWithCase battery")
        }
    }

    func testANC() {
        let ancRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.anc, payload: [], operationID: 0x01)
        XCTAssertEqual(ancRequest.toBytes(), [0x55, 0x60, 0x01, 0x1E, 0xC0, 0x00, 0x00, 0x01, 0xB1, 0x1D])

        let ancWriteRequest = BluetoothRequest.setANCMode(.active(.low), operationID: 0x01)
        XCTAssertEqual(ancWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x0F, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x03, 0x00, 0xF8, 0xB7])

        let ancResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01,
            0x00, 0x03
        ]
        guard let ancResponse = BluetoothResponse(data: ancResponseBytes) else {
            XCTFail("Failed to parse ANC response")
            return
        }
        XCTAssertEqual(ancResponse.parseANCMode(), .active(.low))
    }

    func testEnhancedBass() {
        let enhancedBassRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.enhancedBass, payload: [], operationID: 0x01)
        XCTAssertEqual(enhancedBassRequest.toBytes(), [0x55, 0x60, 0x01, 0x4E, 0xC0, 0x00, 0x00, 0x01, 0x71, 0x11])

        let enhancedBassWriteRequest = BluetoothRequest.setEnhancedBass(.init(isEnabled: true, level: 55), operationID: 0x01)
        XCTAssertEqual(enhancedBassWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x51, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x6E, 0xF6, 0xD1])

        let enhancedBassResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x4E, 0x40, 0x02, 0x00, 0x01,
            0x01, 0x6E
        ]
        guard let enhancedBassResponse = BluetoothResponse(data: enhancedBassResponseBytes) else {
            XCTFail("Failed to parse enhanced bass response")
            return
        }
        let enhancedBass = enhancedBassResponse.parseEnhancedBassSettings()
        XCTAssertEqual(enhancedBass?.isEnabled, true)
        XCTAssertEqual(enhancedBass?.level, 55)
    }

    func testEQPreset() {
        let eqRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.eq, payload: [], operationID: 0x01)
        XCTAssertEqual(eqRequest.toBytes(), [0x55, 0x60, 0x01, 0x1F, 0xC0, 0x00, 0x00, 0x01, 0x8C, 0xDD])

        let eqWriteRequest = BluetoothRequest.setEQPreset(.advanced, operationID: 0x01)
        XCTAssertEqual(eqWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x10, 0xF0, 0x02, 0x00, 0x01, 0x06, 0x00, 0x24, 0x09])

        let eqResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x1F, 0x40, 0x01, 0x00, 0x01,
            0x06
        ]
        guard let eqResponse = BluetoothResponse(data: eqResponseBytes) else {
            XCTFail("Failed to parse EQ response")
            return
        }
        XCTAssertEqual(eqResponse.parseEQPreset(), .advanced)
    }

    func testInEarDetection() {
        let inEarRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.inEarDetection, payload: [], operationID: 0x01)
        XCTAssertEqual(inEarRequest.toBytes(), [0x55, 0x60, 0x01, 0x0E, 0xC0, 0x00, 0x00, 0x01, 0x70, 0xDE])

        let inEarWriteRequest = BluetoothRequest.setInEarDetection(true, operationID: 0x01)
        XCTAssertEqual(inEarWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x04, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x01, 0x01, 0x79, 0xA4])

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

        let latencyWriteRequest = BluetoothRequest.setLowLatency(false, operationID: 0x01)
        XCTAssertEqual(latencyWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x40, 0xF0, 0x02, 0x00, 0x01, 0x02, 0x00, 0x76, 0xCC])

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

        let gestureWriteRequest = BluetoothRequest.setGesture(.init(type: .trippleTap, action: .volumeUp, device: .right), operationID: 0x01)
        XCTAssertEqual(gestureWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x03, 0xF0, 0x05, 0x00, 0x01, 0x01, 0x03, 0x01, 0x03, 0x04, 0x13, 0x50])

        let gestureResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x18, 0x40, 0x05, 0x00, 0x01,
            0x01, 0x03, 0x00, 0x03, 0x04
        ]
        guard let gestureResponse = BluetoothResponse(data: gestureResponseBytes) else {
            XCTFail("Failed to parse gesture response")
            return
        }
        let gestures = gestureResponse.parseGestures()
        XCTAssertEqual(gestures.count, 1)
        XCTAssertEqual(gestures.first?.device, .right)
        XCTAssertEqual(gestures.first?.type, .trippleTap)
        XCTAssertEqual(gestures.first?.action, .volumeUp)
    }

    func testRingBuds() {
        let ringBudsRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.ringBuds, payload: [], operationID: 0x01)
        XCTAssertEqual(ringBudsRequest.toBytes(), [0x55, 0x60, 0x01, 0x02, 0xC0, 0x00, 0x00, 0x01, 0x60, 0xDF])

        let ringBudsWriteRequest = BluetoothRequest.setRingBuds(.init(isOn: true, bud: .left), operationID: 0x01)
        XCTAssertEqual(ringBudsWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x02, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x01, 0xD5, 0xF8])

        let ringBudsResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x02, 0x40, 0x03, 0x00, 0x01,
            0x00, 0x01, 0x01
        ]
        guard let ringBudsResponse = BluetoothResponse(data: ringBudsResponseBytes) else {
            XCTFail("Failed to parse ring buds response")
            return
        }
        let ringBuds = ringBudsResponse.parseRingBuds()
        XCTAssertEqual(ringBuds?.bud, .left)
        XCTAssertEqual(ringBuds?.isOn, true)
    }

    func testModelDetectionByNameAndSerial() {
        let cases: [(String, DeviceModel)] = [
            ("SH006201000000", .ear(.white)),
            ("SH006101000000", .ear(.black))
        ]

        for (serial, expected) in cases {
            XCTAssertEqual(DeviceModel.getModel(from: serial), expected)
            XCTAssertEqual(DeviceModel.getModel(for: "Nothing Ear", serialNumber: serial), expected)
        }
    }

    func testCustomEQPreset() {
        let model = DeviceModel.ear(.white)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
