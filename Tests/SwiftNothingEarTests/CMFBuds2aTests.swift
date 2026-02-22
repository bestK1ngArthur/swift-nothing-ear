import XCTest
@testable import SwiftNothingEar

final class CMFBuds2aTests: XCTestCase {

    func testModelMetadata() {
        let model = DeviceModel.cmfBuds2a(.darkGrey)

        XCTAssertEqual(model.displayName, "CMF Buds 2a")
        XCTAssertEqual(model.code, "B185")
        XCTAssertTrue(model.isCMF)
    }

    func testModelDetectionByNameWhenSerialIsUnknown() {
        let unknownSerial = "SH009801000000"

        XCTAssertNil(DeviceModel.getModel(from: unknownSerial))
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Buds 2a", serialNumber: unknownSerial),
            .cmfBuds2a(.darkGrey)
        )
        XCTAssertEqual(
            DeviceModel.getModel(for: "CMF Buds 2A", serialNumber: unknownSerial),
            .cmfBuds2a(.darkGrey)
        )
    }

    func testCapabilities() {
        let model = DeviceModel.cmfBuds2a(.lightGrey)

        XCTAssertTrue(model.supportsNoiseCancellation)
        XCTAssertFalse(model.supportsSpatialAudio)
        XCTAssertTrue(model.supportsEnhancedBass)
        XCTAssertTrue(model.supportsEQ)
        XCTAssertTrue(model.supportsCustomEQ)
        XCTAssertTrue(model.supportsRingBuds)
    }

    func testCustomEQPreset() {
        let model = DeviceModel.cmfBuds2a(.darkGrey)
        let preset = EQPresetCustom(bass: 6, mid: 0, treble: -3)

        assertCustomEQWrite(for: model, preset: preset)
        assertCustomEQRead(preset: preset)
    }
}
