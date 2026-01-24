import XCTest
@testable import SwiftNothingEar

final class NothingHeadphone1Tests: XCTestCase {

    func testBattery() {
        let model = DeviceModel.headphone1(.black)

        let batteryRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.battery, payload: [], operationID: 0x01)
        XCTAssertEqual(batteryRequest.toBytes(), [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x01, 0xAC, 0xDF])

        let batteryResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x07, 0x40, 0x03, 0x00, 0x01,
            0x00, 0x00, 0xD8
        ]
        guard let batteryResponse = BluetoothResponse(data: batteryResponseBytes) else {
            XCTFail("Failed to parse battery response")
            return
        }
        if case .single(let level) = batteryResponse.parseBattery(model: model) {
            XCTAssertEqual(level.level, 88)
            XCTAssertEqual(level.isCharging, true)
        } else {
            XCTFail("Expected single battery")
        }
    }

    func testANC() {
        let ancRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.anc, payload: [], operationID: 0x01)
        XCTAssertEqual(ancRequest.toBytes(), [0x55, 0x60, 0x01, 0x1E, 0xC0, 0x00, 0x00, 0x01, 0xB1, 0x1D])

        let ancWriteRequest = BluetoothRequest.setANCMode(.active(.high), operationID: 0x01)
        XCTAssertEqual(ancWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x0F, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x01, 0x00, 0xF9, 0xD7])

        let ancResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x1E, 0x40, 0x02, 0x00, 0x01,
            0x00, 0x01
        ]
        guard let ancResponse = BluetoothResponse(data: ancResponseBytes) else {
            XCTFail("Failed to parse ANC response")
            return
        }
        XCTAssertEqual(ancResponse.parseANCMode(), .active(.high))
    }

    func testSpatialAudio() {
        let spatialRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.spatialAudio, payload: [], operationID: 0x01)
        XCTAssertEqual(spatialRequest.toBytes(), [0x55, 0x60, 0x01, 0x4F, 0xC0, 0x00, 0x00, 0x01, 0x4C, 0xD1])

        let spatialWriteRequest = BluetoothRequest.setSpatialAudioMode(.headTracking, operationID: 0x01)
        XCTAssertEqual(spatialWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x52, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x01, 0x85, 0xFD])

        let spatialResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x4F, 0x40, 0x02, 0x00, 0x01,
            0x01, 0x01
        ]
        guard let spatialResponse = BluetoothResponse(data: spatialResponseBytes) else {
            XCTFail("Failed to parse spatial audio response")
            return
        }
        XCTAssertEqual(spatialResponse.parseSpatialAudioMode(), .headTracking)
    }

    func testEnhancedBass() {
        let enhancedBassRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.enhancedBass, payload: [], operationID: 0x01)
        XCTAssertEqual(enhancedBassRequest.toBytes(), [0x55, 0x60, 0x01, 0x4E, 0xC0, 0x00, 0x00, 0x01, 0x71, 0x11])

        let enhancedBassWriteRequest = BluetoothRequest.setEnhancedBass(.init(isEnabled: true, level: 25), operationID: 0x01)
        XCTAssertEqual(enhancedBassWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x51, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x32, 0xF6, 0xE8])

        let enhancedBassResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x4E, 0x40, 0x02, 0x00, 0x01,
            0x01, 0x32
        ]
        guard let enhancedBassResponse = BluetoothResponse(data: enhancedBassResponseBytes) else {
            XCTFail("Failed to parse enhanced bass response")
            return
        }
        let enhancedBass = enhancedBassResponse.parseEnhancedBassSettings()
        XCTAssertEqual(enhancedBass?.isEnabled, true)
        XCTAssertEqual(enhancedBass?.level, 25)
    }

    func testEQPreset() {
        let eqRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.eq, payload: [], operationID: 0x01)
        XCTAssertEqual(eqRequest.toBytes(), [0x55, 0x60, 0x01, 0x1F, 0xC0, 0x00, 0x00, 0x01, 0x8C, 0xDD])

        let eqWriteRequest = BluetoothRequest.setEQPreset(.moreBass, operationID: 0x01)
        XCTAssertEqual(eqWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x10, 0xF0, 0x02, 0x00, 0x01, 0x03, 0x00, 0x27, 0x59])

        let eqResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x1F, 0x40, 0x01, 0x00, 0x01,
            0x03
        ]
        guard let eqResponse = BluetoothResponse(data: eqResponseBytes) else {
            XCTFail("Failed to parse EQ response")
            return
        }
        XCTAssertEqual(eqResponse.parseEQPreset(), .moreBass)
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

        let latencyWriteRequest = BluetoothRequest.setLowLatency(true, operationID: 0x01)
        XCTAssertEqual(latencyWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x40, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x00, 0x76, 0x3C])

        let latencyResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x41, 0x40, 0x01, 0x00, 0x01,
            0x01
        ]
        guard let latencyResponse = BluetoothResponse(data: latencyResponseBytes) else {
            XCTFail("Failed to parse low latency response")
            return
        }
        XCTAssertEqual(latencyResponse.parseLowLatency(), true)
    }

    func testGestures() {
        let gestureRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.gesture, payload: [], operationID: 0x01)
        XCTAssertEqual(gestureRequest.toBytes(), [0x55, 0x60, 0x01, 0x18, 0xC0, 0x00, 0x00, 0x01, 0x39, 0x1D])

        let gestureWriteRequest = BluetoothRequest.setGesture(.init(type: .longPress, action: .ancToggle, device: .right), operationID: 0x01)
        XCTAssertEqual(gestureWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x03, 0xF0, 0x05, 0x00, 0x01, 0x01, 0x03, 0x01, 0x0B, 0x07, 0x54, 0x91])

        let gestureResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x18, 0x40, 0x05, 0x00, 0x01,
            0x01, 0x03, 0x00, 0x0B, 0x07
        ]
        guard let gestureResponse = BluetoothResponse(data: gestureResponseBytes) else {
            XCTFail("Failed to parse gesture response")
            return
        }
        let gestures = gestureResponse.parseGestures()
        XCTAssertEqual(gestures.count, 1)
        XCTAssertEqual(gestures.first?.device, .right)
        XCTAssertEqual(gestures.first?.type, .longPress)
        XCTAssertEqual(gestures.first?.action, .ancToggle)
    }

    func testRingBuds() {
        let ringBudsRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.ringBuds, payload: [], operationID: 0x01)
        XCTAssertEqual(ringBudsRequest.toBytes(), [0x55, 0x60, 0x01, 0x02, 0xC0, 0x00, 0x00, 0x01, 0x60, 0xDF])

        let ringBudsWriteRequest = BluetoothRequest.setRingBuds(.init(isOn: true, bud: .unibody), operationID: 0x01)
        XCTAssertEqual(ringBudsWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x02, 0xF0, 0x02, 0x00, 0x01, 0x06, 0x01, 0xD7, 0xC8])

        let ringBudsResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x02, 0x40, 0x03, 0x00, 0x01,
            0x00, 0x06, 0x01
        ]
        guard let ringBudsResponse = BluetoothResponse(data: ringBudsResponseBytes) else {
            XCTFail("Failed to parse ring buds response")
            return
        }
        let ringBuds = ringBudsResponse.parseRingBuds()
        XCTAssertEqual(ringBuds?.bud, .unibody)
        XCTAssertEqual(ringBuds?.isOn, true)
    }

    func testModelDetectionByNameAndSerial() {
        let cases: [(String, DeviceModel)] = [
            ("M3A603000000", .headphone1(.black)),
            ("M3A606000000", .headphone1(.grey))
        ]

        for (serial, expected) in cases {
            XCTAssertEqual(DeviceModel.getModel(from: serial), expected)
            XCTAssertEqual(DeviceModel.getModel(for: "Nothing Headphone (1)", serialNumber: serial), expected)
        }
    }

    func testCustomEQPreset() {
        let model = DeviceModel.headphone1(.black)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
