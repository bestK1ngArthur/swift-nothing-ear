import XCTest
@testable import SwiftNothingEar

final class NothingEar3aTests: XCTestCase {

    func testModelMetadata() {
        let model = DeviceModel.ear3A(.black)

        XCTAssertEqual(model.displayName, "Nothing Ear (3a)")
        XCTAssertEqual(model.code, "B190")
        XCTAssertFalse(model.isCMF)
    }

    func testModelDetectionByNameWhenSerialIsUnknown() {
        let unknownSerial = "SH009801000000"

        XCTAssertNil(DeviceModel.getModel(from: unknownSerial))
        XCTAssertEqual(
            DeviceModel.getModel(for: "Nothing Ear (3a)", serialNumber: unknownSerial),
            .ear3A(.black)
        )
    }

    func testModelDetectionPrefersNameWhenSerialHasDifferentModel() {
        XCTAssertEqual(
            DeviceModel.getModel(for: "Nothing Ear (3a)", serialNumber: "SH002501000000"),
            .ear3A(.black)
        )
    }

    func testCapabilities() {
        let models: [DeviceModel] = [
            .ear3A(.black),
            .ear3A(.white),
            .ear3A(.yellow),
            .ear3A(.pink)
        ]

        for model in models {
            XCTAssertTrue(model.supportsNoiseCancellation)
            XCTAssertTrue(model.supportsSpatialAudio)
            XCTAssertFalse(model.supportsEnhancedBass)
            XCTAssertTrue(model.supportsEQ)
            XCTAssertTrue(model.supportsCustomEQ)
            XCTAssertTrue(model.supportsRingBuds)
        }
    }

    func testSpatialAudioModes() {
        XCTAssertEqual(
            SpatialAudioMode.allSupported(by: .ear3A(.black)),
            [.off, .fixed]
        )
        XCTAssertFalse(SpatialAudioMode.isCompatibleWithEnhancedBass(by: .ear3A(.black)))
    }

    func testBattery() throws {
        let batteryRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.battery, payload: [], operationID: 0x01)
        XCTAssertEqual(batteryRequest.toBytes(), [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x01, 0xAC, 0xDF])

        throw XCTSkip("Captured Nothing Ear (3a) battery response bytes are not available.")
    }

    func testANC() throws {
        let ancRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.anc, payload: [], operationID: 0x01)
        XCTAssertEqual(ancRequest.toBytes(), [0x55, 0x60, 0x01, 0x1E, 0xC0, 0x00, 0x00, 0x01, 0xB1, 0x1D])

        let ancWriteRequest = BluetoothRequest.setANCMode(.active(.adaptive), operationID: 0x01)
        XCTAssertEqual(ancWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x0F, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x04, 0x00, 0xFA, 0x87])

        throw XCTSkip("Captured Nothing Ear (3a) ANC response bytes are not available.")
    }

    func testSpatialAudio() throws {
        let spatialRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.spatialAudio, payload: [], operationID: 0x01)
        XCTAssertEqual(spatialRequest.toBytes(), [0x55, 0x60, 0x01, 0x4F, 0xC0, 0x00, 0x00, 0x01, 0x4C, 0xD1])

        let spatialWriteRequest = BluetoothRequest.setSpatialAudioMode(.fixed, operationID: 0x01)
        XCTAssertEqual(spatialWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x52, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x00, 0x44, 0x3D])

        throw XCTSkip("Captured Nothing Ear (3a) spatial audio response bytes are not available.")
    }

    func testEQPreset() throws {
        let eqRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.eq, payload: [], operationID: 0x01)
        XCTAssertEqual(eqRequest.toBytes(), [0x55, 0x60, 0x01, 0x1F, 0xC0, 0x00, 0x00, 0x01, 0x8C, 0xDD])

        let eqWriteRequest = BluetoothRequest.setEQPreset(.voice, operationID: 0x01)
        XCTAssertEqual(eqWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x10, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x00, 0x26, 0x39])

        throw XCTSkip("Captured Nothing Ear (3a) EQ response bytes are not available.")
    }

    func testGestures() throws {
        let gestureRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.gesture, payload: [], operationID: 0x01)
        XCTAssertEqual(gestureRequest.toBytes(), [0x55, 0x60, 0x01, 0x18, 0xC0, 0x00, 0x00, 0x01, 0x39, 0x1D])

        let gestureWriteRequest = BluetoothRequest.setGesture(.init(type: .doubleTap, action: .nextTrack, device: .left), operationID: 0x01)
        XCTAssertEqual(gestureWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x03, 0xF0, 0x05, 0x00, 0x01, 0x01, 0x02, 0x01, 0x02, 0x02, 0x93, 0x3E])

        throw XCTSkip("Captured Nothing Ear (3a) gesture response bytes are not available.")
    }

    func testInEarDetection() throws {
        let inEarRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.inEarDetection, payload: [], operationID: 0x01)
        XCTAssertEqual(inEarRequest.toBytes(), [0x55, 0x60, 0x01, 0x0E, 0xC0, 0x00, 0x00, 0x01, 0x70, 0xDE])

        let inEarWriteRequest = BluetoothRequest.setInEarDetection(false, operationID: 0x01)
        XCTAssertEqual(inEarWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x04, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x01, 0x00, 0xB8, 0x64])

        throw XCTSkip("Captured Nothing Ear (3a) in-ear detection response bytes are not available.")
    }

    func testLowLatency() throws {
        let latencyRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.lowLatency, payload: [], operationID: 0x01)
        XCTAssertEqual(latencyRequest.toBytes(), [0x55, 0x60, 0x01, 0x41, 0xC0, 0x00, 0x00, 0x01, 0x25, 0x10])

        let latencyWriteRequest = BluetoothRequest.setLowLatency(true, operationID: 0x01)
        XCTAssertEqual(latencyWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x40, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x00, 0x76, 0x3C])

        throw XCTSkip("Captured Nothing Ear (3a) low latency response bytes are not available.")
    }

    func testRingBuds() throws {
        let ringBudsRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.ringBuds, payload: [], operationID: 0x01)
        XCTAssertEqual(ringBudsRequest.toBytes(), [0x55, 0x60, 0x01, 0x02, 0xC0, 0x00, 0x00, 0x01, 0x60, 0xDF])

        let ringBudsWriteRequest = BluetoothRequest.setRingBuds(.init(isOn: true, bud: .unibody), operationID: 0x01)
        XCTAssertEqual(ringBudsWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x02, 0xF0, 0x02, 0x00, 0x01, 0x06, 0x01, 0xD7, 0xC8])

        throw XCTSkip("Captured Nothing Ear (3a) ring buds response bytes are not available.")
    }

    func testCustomEQPreset() {
        let model = DeviceModel.ear3A(.black)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
