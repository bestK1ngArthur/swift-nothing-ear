import XCTest
@testable import SwiftNothingEar

final class CMFClipProTests: XCTestCase {

    func testModelMetadata() {
        let model = DeviceModel.cmfClipPro(.darkGrey)

        XCTAssertEqual(model.displayName, "CMF Clip Pro")
        XCTAssertEqual(model.code, "B189")
        XCTAssertTrue(model.isCMF)
    }

    func testModelDetectionByNameWhenSerialIsUnknown() {
        let unknownSerial = "SH009801000000"

        XCTAssertNil(DeviceModel.getModel(from: unknownSerial))
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Clip Pro", serialNumber: unknownSerial),
            .cmfClipPro(.darkGrey)
        )
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Clip Pro", serialNumber: ""),
            .cmfClipPro(.darkGrey)
        )
    }

    func testModelDetectionPrefersNameWhenSerialHasDifferentModel() {
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Clip Pro", serialNumber: "SH002501000000"),
            .cmfClipPro(.darkGrey)
        )
    }

    func testCapabilities() {
        let models: [DeviceModel] = [
            .cmfClipPro(.darkGrey),
            .cmfClipPro(.lightGrey),
            .cmfClipPro(.coral)
        ]

        for model in models {
            XCTAssertFalse(model.supportsNoiseCancellation)
            XCTAssertTrue(model.supportsSpatialAudio)
            XCTAssertTrue(model.supportsEnhancedBass)
            XCTAssertTrue(model.supportsEQ)
            XCTAssertTrue(model.supportsCustomEQ)
            XCTAssertTrue(model.supportsRingBuds)
            XCTAssertFalse(model.supportsInEarDetection)
            XCTAssertFalse(model.supportsListeningMode)
            XCTAssertEqual(
                EQPreset.allSupported(by: model),
                [.balanced, .voice, .moreTreble, .moreBass, .custom]
            )
        }
    }

    func testSpatialAudioModes() {
        XCTAssertEqual(
            SpatialAudioMode.allSupported(by: .cmfClipPro(.darkGrey)),
            [.off, .fixed]
        )
        XCTAssertTrue(
            SpatialAudioMode.isCompatibleWithEnhancedBass(by: .cmfClipPro(.darkGrey))
        )
    }

    func testBattery() throws {
        let batteryRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.battery,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            batteryRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x01, 0xAC, 0xDF]
        )

        throw XCTSkip("Captured CMF Clip Pro battery response bytes are not available.")
    }

    func testSpatialAudio() throws {
        let spatialRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.spatialAudio,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            spatialRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x4F, 0xC0, 0x00, 0x00, 0x01, 0x4C, 0xD1]
        )

        let spatialWriteRequest = BluetoothRequest.setSpatialAudioMode(.fixed, operationID: 0x01)
        XCTAssertEqual(
            spatialWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x52, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x00, 0x44, 0x3D]
        )

        throw XCTSkip("Captured CMF Clip Pro spatial audio response bytes are not available.")
    }

    func testEnhancedBass() throws {
        let enhancedBassRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.enhancedBass,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            enhancedBassRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x4E, 0xC0, 0x00, 0x00, 0x01, 0x71, 0x11]
        )

        let enhancedBassWriteRequest = BluetoothRequest.setEnhancedBass(
            .init(isEnabled: true, level: 3),
            operationID: 0x01
        )
        XCTAssertEqual(
            enhancedBassWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x51, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x06, 0xF7, 0x3F]
        )

        throw XCTSkip("Captured CMF Clip Pro Ultra Bass response bytes are not available.")
    }

    func testEQPreset() throws {
        let eqRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.eq,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            eqRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x1F, 0xC0, 0x00, 0x00, 0x01, 0x8C, 0xDD]
        )

        let eqWriteRequest = BluetoothRequest.setEQPreset(.voice, operationID: 0x01)
        XCTAssertEqual(
            eqWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x10, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x00, 0x26, 0x39]
        )

        throw XCTSkip("Captured CMF Clip Pro EQ response bytes are not available.")
    }

    func testGestures() throws {
        let gestureRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.gesture,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            gestureRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x18, 0xC0, 0x00, 0x00, 0x01, 0x39, 0x1D]
        )

        let gestureWriteRequest = BluetoothRequest.setGesture(
            .init(type: .doubleTap, action: .nextTrack, device: .right),
            operationID: 0x01
        )
        XCTAssertEqual(
            gestureWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x03, 0xF0, 0x05, 0x00, 0x01, 0x01, 0x03, 0x01, 0x02, 0x02, 0x92, 0xC2]
        )

        throw XCTSkip("Captured CMF Clip Pro gesture response bytes are not available.")
    }

    func testLowLatency() throws {
        let latencyRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.lowLatency,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            latencyRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x41, 0xC0, 0x00, 0x00, 0x01, 0x25, 0x10]
        )

        let latencyWriteRequest = BluetoothRequest.setLowLatency(true, operationID: 0x01)
        XCTAssertEqual(
            latencyWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x40, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x00, 0x76, 0x3C]
        )

        throw XCTSkip("Captured CMF Clip Pro low latency response bytes are not available.")
    }

    func testRingBuds() throws {
        let ringBudsRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.ringBuds,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            ringBudsRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x02, 0xC0, 0x00, 0x00, 0x01, 0x60, 0xDF]
        )

        let ringBudsWriteRequest = BluetoothRequest.setRingBuds(
            .init(isOn: true, bud: .left),
            operationID: 0x01
        )
        XCTAssertEqual(
            ringBudsWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x02, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x01, 0xD5, 0xF8]
        )

        throw XCTSkip("Captured CMF Clip Pro Find My response bytes are not available.")
    }

    func testCustomEQPreset() {
        let model = DeviceModel.cmfClipPro(.darkGrey)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
