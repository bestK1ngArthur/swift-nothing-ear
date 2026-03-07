import XCTest
@testable import SwiftNothingEar

final class NothingHeadphoneATests: XCTestCase {

    func testModelMetadata() {
        let model = DeviceModel.headphoneA(.black)

        XCTAssertEqual(model.displayName, "Nothing Headphone (a)")
        XCTAssertEqual(model.code, "B186")
        XCTAssertFalse(model.isCMF)
    }

    func testModelDetectionByNameWhenSerialIsUnknown() {
        let unknownSerial = "M3A699000000"

        XCTAssertNil(DeviceModel.getModel(from: unknownSerial))
        XCTAssertEqual(
            DeviceModel.getModel(for: "Nothing Headphone (a)", serialNumber: unknownSerial),
            .headphoneA(.black)
        )
    }

    func testModelDetectionPrefersNameWhenSerialHasDifferentModel() {
        XCTAssertEqual(
            DeviceModel.getModel(for: "Nothing Headphone (a)", serialNumber: "M3A603000000"),
            .headphoneA(.black)
        )
    }

    func testCapabilities() {
        let models: [DeviceModel] = [
            .headphoneA(.black),
            .headphoneA(.white),
            .headphoneA(.yellow),
            .headphoneA(.pink)
        ]

        for model in models {
            XCTAssertTrue(model.supportsNoiseCancellation)
            XCTAssertTrue(model.supportsSpatialAudio)
            XCTAssertTrue(model.supportsEnhancedBass)
            XCTAssertTrue(model.supportsEQ)
            XCTAssertTrue(model.supportsCustomEQ)
            XCTAssertTrue(model.supportsRingBuds)
        }
    }

    func testSpatialAudioModes() {
        XCTAssertEqual(
            SpatialAudioMode.allSupported(by: .headphoneA(.black)),
            [.off, .fixed, .headTracking]
        )
    }

    func testBattery() {
        let model = DeviceModel.headphoneA(.black)
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

    func testCustomEQPreset() {
        let model = DeviceModel.headphoneA(.black)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
