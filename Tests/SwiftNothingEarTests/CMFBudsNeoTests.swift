import XCTest
@testable import SwiftNothingEar

final class CMFBudsNeoTests: XCTestCase {

    func testModelMetadata() {
        let model = DeviceModel.cmfBudsNeo(.black)

        XCTAssertEqual(model.displayName, "CMF Buds Neo")
        XCTAssertEqual(model.code, "B193")
        XCTAssertTrue(model.isCMF)
    }

    func testModelDetectionByNameWhenSerialIsUnknown() {
        let unknownSerial = "SH009801000000"

        XCTAssertNil(DeviceModel.getModel(from: unknownSerial))
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Buds Neo", serialNumber: unknownSerial),
            .cmfBudsNeo(.black)
        )
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Buds Neo", serialNumber: ""),
            .cmfBudsNeo(.black)
        )
    }

    func testModelDetectionPrefersNameWhenSerialHasDifferentModel() {
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Buds Neo", serialNumber: "SH002501000000"),
            .cmfBudsNeo(.black)
        )
    }

    func testModelDetectionBySerial() throws {
        throw XCTSkip("Captured CMF Buds Neo serial SKU mappings are not available.")
    }

    func testCapabilities() {
        let models: [DeviceModel] = [
            .cmfBudsNeo(.black),
            .cmfBudsNeo(.white),
            .cmfBudsNeo(.darkBlue)
        ]

        for model in models {
            XCTAssertTrue(model.supportsNoiseCancellation)
            XCTAssertTrue(model.supportsSpatialAudio)
            XCTAssertTrue(model.supportsEnhancedBass)
            XCTAssertTrue(model.supportsEQ)
            XCTAssertTrue(model.supportsCustomEQ)
            XCTAssertTrue(model.supportsRingBuds)
            XCTAssertFalse(model.supportsInEarDetection)
            XCTAssertTrue(model.supportsListeningMode)
            XCTAssertEqual(
                EQPreset.allSupported(by: model),
                [.balanced, .voice, .moreTreble, .moreBass, .custom]
            )
        }
    }

    func testSpatialAudioModes() {
        XCTAssertEqual(
            SpatialAudioMode.allSupported(by: .cmfBudsNeo(.black)),
            [.off, .fixed]
        )
        XCTAssertTrue(
            SpatialAudioMode.isCompatibleWithEnhancedBass(by: .cmfBudsNeo(.black))
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

        throw XCTSkip("Captured CMF Buds Neo battery response bytes are not available.")
    }

    func testANC() throws {
        let ancRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.anc,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            ancRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x1E, 0xC0, 0x00, 0x00, 0x01, 0xB1, 0x1D]
        )

        let ancWriteRequest = BluetoothRequest.setANCMode(.active(.adaptive), operationID: 0x01)
        XCTAssertEqual(
            ancWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x0F, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x04, 0x00, 0xFA, 0x87]
        )

        throw XCTSkip("Captured CMF Buds Neo ANC response bytes are not available.")
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

        throw XCTSkip("Captured CMF Buds Neo spatial audio response bytes are not available.")
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
            .init(isEnabled: true, level: 50),
            operationID: 0x01
        )
        XCTAssertEqual(
            enhancedBassWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x51, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x64, 0x76, 0xD6]
        )

        throw XCTSkip("Captured CMF Buds Neo Ultra Bass response bytes are not available.")
    }

    func testEQPreset() throws {
        let eqRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.listeningMode,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            eqRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x50, 0xC0, 0x00, 0x00, 0x01, 0xD9, 0x13]
        )

        let eqWriteRequest = BluetoothRequest.setEQPreset(.balanced, operationID: 0x01)
        XCTAssertEqual(
            eqWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x10, 0xF0, 0x02, 0x00, 0x01, 0x00, 0x00, 0x27, 0xA9]
        )

        throw XCTSkip("Captured CMF Buds Neo EQ response bytes are not available.")
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
            .init(type: .doubleTap, action: .nextTrack, device: .left),
            operationID: 0x01
        )
        XCTAssertEqual(
            gestureWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x03, 0xF0, 0x05, 0x00, 0x01, 0x01, 0x02, 0x01, 0x02, 0x02, 0x93, 0x3E]
        )

        throw XCTSkip("Captured CMF Buds Neo gesture response bytes are not available.")
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

        throw XCTSkip("Captured CMF Buds Neo low latency response bytes are not available.")
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

        throw XCTSkip("Captured CMF Buds Neo Find My response bytes are not available.")
    }

    func testCustomEQPreset() {
        let model = DeviceModel.cmfBudsNeo(.black)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
