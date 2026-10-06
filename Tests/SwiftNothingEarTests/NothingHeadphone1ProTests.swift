import XCTest
@testable import SwiftNothingEar

final class NothingHeadphone1ProTests: XCTestCase {

    func testModelMetadata() {
        let model = DeviceModel.headphone1Pro(.black)

        XCTAssertEqual(model.displayName, "Nothing Headphone (1) Pro")
        XCTAssertEqual(model.code, "B192")
        XCTAssertFalse(model.isCMF)
    }

    func testModelDetectionByNameWhenSerialIsUnknown() {
        let unknownSerial = "M3A699000000"

        XCTAssertNil(DeviceModel.getModel(from: unknownSerial))
        XCTAssertEqual(
            DeviceModel.getModel(for: "Nothing Headphone (1) Pro", serialNumber: unknownSerial),
            .headphone1Pro(.black)
        )
        XCTAssertEqual(
            DeviceModel.getModel(for: "Nothing Headphone (1) Pro", serialNumber: ""),
            .headphone1Pro(.black)
        )
    }

    func testModelDetectionPrefersNameWhenSerialHasDifferentModel() {
        XCTAssertEqual(
            DeviceModel.getModel(for: "Nothing Headphone (1) Pro", serialNumber: "M3A603000000"),
            .headphone1Pro(.black)
        )
    }

    func testModelDetectionBySerial() throws {
        throw XCTSkip("Captured Nothing Headphone (1) Pro serial SKU mappings are not available.")
    }

    func testCapabilities() {
        let models: [DeviceModel] = [
            .headphone1Pro(.black),
            .headphone1Pro(.silver)
        ]

        for model in models {
            XCTAssertTrue(model.supportsNoiseCancellation)
            XCTAssertTrue(model.supportsSpatialAudio)
            XCTAssertFalse(model.supportsEnhancedBass)
            XCTAssertTrue(model.supportsEQ)
            XCTAssertTrue(model.supportsCustomEQ)
            XCTAssertTrue(model.supportsRingBuds)
            XCTAssertTrue(model.supportsInEarDetection)
            XCTAssertFalse(model.supportsListeningMode)
            XCTAssertEqual(
                EQPreset.allSupported(by: model),
                [.balanced, .voice, .moreTreble, .moreBass, .newInstrument, .custom, .advanced]
            )
        }
    }

    func testSpatialAudioModes() {
        XCTAssertEqual(
            SpatialAudioMode.allSupported(by: .headphone1Pro(.black)),
            [.off, .fixed, .headTracking]
        )
        XCTAssertFalse(
            SpatialAudioMode.isCompatibleWithEnhancedBass(by: .headphone1Pro(.black))
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

        throw XCTSkip("Captured Nothing Headphone (1) Pro battery response bytes are not available.")
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

        let ancWriteRequest = BluetoothRequest.setANCMode(.active(.high), operationID: 0x01)
        XCTAssertEqual(
            ancWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x0F, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x01, 0x00, 0xF9, 0xD7]
        )

        throw XCTSkip("Captured Nothing Headphone (1) Pro ANC response bytes are not available.")
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

        let spatialWriteRequest = BluetoothRequest.setSpatialAudioMode(.headTracking, operationID: 0x01)
        XCTAssertEqual(
            spatialWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x52, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x01, 0x85, 0xFD]
        )

        throw XCTSkip("Captured Nothing Headphone (1) Pro spatial audio response bytes are not available.")
    }

    func testEnhancedBass() {
        XCTAssertFalse(EnhancedBass.isSupported(by: .headphone1Pro(.black)))
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

        let eqWriteRequest = BluetoothRequest.setEQPreset(.moreBass, for: .headphone1Pro(.black), operationID: 0x01)
        XCTAssertEqual(
            eqWriteRequest?.toBytes(),
            [0x55, 0x60, 0x01, 0x10, 0xF0, 0x02, 0x00, 0x01, 0x03, 0x00, 0x27, 0x59]
        )

        let instrumentWriteRequest = BluetoothRequest.setEQPreset(.newInstrument, for: .headphone1Pro(.black), operationID: 0x01)
        XCTAssertEqual(
            instrumentWriteRequest?.toBytes(),
            [0x55, 0x60, 0x01, 0x10, 0xF0, 0x02, 0x00, 0x01, 0x07, 0x00, 0x25, 0x99]
        )

        throw XCTSkip("Captured Nothing Headphone (1) Pro EQ response bytes are not available.")
    }

    func testGestures() throws {
        throw XCTSkip("Headphone button, wheel and paddle gestures are not implemented by this package.")
    }

    func testInEarDetection() throws {
        let inEarRequest = BluetoothRequest(
            command: BluetoothCommand.RequestRead.inEarDetection,
            payload: [],
            operationID: 0x01
        )
        XCTAssertEqual(
            inEarRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x0E, 0xC0, 0x00, 0x00, 0x01, 0x70, 0xDE]
        )

        let inEarWriteRequest = BluetoothRequest.setInEarDetection(true, operationID: 0x01)
        XCTAssertEqual(
            inEarWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x04, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x01, 0x01, 0x79, 0xA4]
        )

        throw XCTSkip("Captured Nothing Headphone (1) Pro in-ear detection response bytes are not available.")
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

        throw XCTSkip("Captured Nothing Headphone (1) Pro low latency response bytes are not available.")
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
            .init(isOn: true, bud: .unibody),
            operationID: 0x01
        )
        XCTAssertEqual(
            ringBudsWriteRequest.toBytes(),
            [0x55, 0x60, 0x01, 0x02, 0xF0, 0x02, 0x00, 0x01, 0x06, 0x01, 0xD7, 0xC8]
        )

        throw XCTSkip("Captured Nothing Headphone (1) Pro Find My response bytes are not available.")
    }

    func testCustomEQPreset() {
        let model = DeviceModel.headphone1Pro(.black)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
