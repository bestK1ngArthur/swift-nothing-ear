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

    func testInEarDetection() {
        XCTAssertFalse(DeviceModel.cmfBuds2a(.darkGrey).supportsInEarDetection)
    }

    func testSupportedEQPresets() {
        XCTAssertEqual(
            EQPreset.allSupported(by: .cmfBuds2a(.darkGrey)),
            [.balanced, .pop, .rock, .electronic, .enhanceVocals, .classical, .custom]
        )

        // Buds 2a uses 7 rather than 0 for its default sound.
        let balancedWriteRequest = BluetoothRequest.setEQPreset(.balanced, for: .cmfBuds2a(.darkGrey), operationID: 0x01)
        XCTAssertEqual(balancedWriteRequest?.toBytes(), [0x55, 0x60, 0x01, 0x1D, 0xF0, 0x02, 0x00, 0x01, 0x07, 0x00, 0xF9, 0x59])
        XCTAssertEqual(EQPreset.from8BitValue(0x07, for: .cmfBuds2a(.darkGrey)), .balanced)
    }

    func testSupportedANCModes() {
        XCTAssertEqual(NoiseCancellationMode.Active.allSupported(by: .cmfBuds2a(.darkGrey)), [.low, .mid, .high])
        XCTAssertEqual(NoiseCancellationMode.allSupported(by: .cmfBuds2a(.darkGrey)), [.active(.high), .transparent, .off])
    }
}
