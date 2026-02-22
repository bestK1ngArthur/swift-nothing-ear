import XCTest
@testable import SwiftNothingEar

final class CMFBuds2PlusTests: XCTestCase {

    func testModelMetadata() {
        let model = DeviceModel.cmfBuds2Plus(.lightGrey)

        XCTAssertEqual(model.displayName, "CMF Buds 2 Plus")
        XCTAssertEqual(model.code, "B184")
        XCTAssertTrue(model.isCMF)
    }

    func testModelDetectionByNameWhenSerialIsUnknown() {
        let unknownSerial = "SH009001000000"

        XCTAssertNil(DeviceModel.getModel(from: unknownSerial))
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Buds 2 Plus", serialNumber: unknownSerial),
            .cmfBuds2Plus(.lightGrey)
        )
    }

    func testCapabilities() {
        let model = DeviceModel.cmfBuds2Plus(.blue)

        XCTAssertTrue(model.supportsNoiseCancellation)
        XCTAssertTrue(model.supportsSpatialAudio)
        XCTAssertTrue(model.supportsEnhancedBass)
        XCTAssertTrue(model.supportsEQ)
        XCTAssertTrue(model.supportsCustomEQ)
        XCTAssertTrue(model.supportsRingBuds)
    }

    func testCustomEQPreset() {
        let model = DeviceModel.cmfBuds2Plus(.lightGrey)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
