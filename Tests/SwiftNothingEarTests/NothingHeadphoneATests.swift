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

    func testANC() {
        let ancWriteRequest = BluetoothRequest.setANCMode(.active(.adaptive), operationID: 0x0E)
        XCTAssertEqual(ancWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x0F, 0xF0, 0x03, 0x00, 0x0E, 0x01, 0x04, 0x00, 0xF9, 0x93])

        // Headphone (a) reports ANC changes with command 0x6003
        let ancNotifications: [([UInt8], NoiseCancellationMode)] = [
            ([0x55, 0x20, 0x03, 0x03, 0x60, 0x03, 0x00, 0x00, 0x01, 0x04, 0x00, 0x70, 0x93], .active(.adaptive)),
            ([0x55, 0x20, 0x03, 0x03, 0x60, 0x03, 0x00, 0x00, 0x01, 0x05, 0x00, 0x71, 0x03], .off),
            ([0x55, 0x20, 0x03, 0x03, 0x60, 0x03, 0x00, 0x00, 0x01, 0x07, 0x00, 0x70, 0x63], .transparent)
        ]

        for (bytes, expectedMode) in ancNotifications {
            guard let ancResponse = BluetoothResponse(data: bytes) else {
                XCTFail("Failed to parse ANC notification")
                continue
            }
            XCTAssertEqual(ancResponse.command, BluetoothCommand.Response.ancC)
            XCTAssertEqual(ancResponse.parseANCMode(), expectedMode)
        }
    }

    func testSpatialAudioModes() {
        XCTAssertEqual(
            SpatialAudioMode.allSupported(by: .headphoneA(.black)),
            [.off, .cinema, .concert]
        )
    }

    func testSpatialAudio() {
        let spatialRequest = BluetoothRequest(command: BluetoothCommand.RequestRead.spatialAudio, payload: [], operationID: 0x0B)
        XCTAssertEqual(spatialRequest.toBytes(), [0x55, 0x60, 0x01, 0x4F, 0xC0, 0x00, 0x00, 0x0B, 0xCC, 0xD6])

        let spatialCinemaWriteRequest = BluetoothRequest.setSpatialAudioMode(.cinema, operationID: 0x12)
        XCTAssertEqual(spatialCinemaWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x52, 0xF0, 0x02, 0x00, 0x12, 0x03, 0x00, 0xB4, 0x98])

        let spatialConcertWriteRequest = BluetoothRequest.setSpatialAudioMode(.concert, operationID: 0x13)
        XCTAssertEqual(spatialConcertWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x52, 0xF0, 0x02, 0x00, 0x13, 0x02, 0x00, 0xE4, 0xC8])

        let spatialOffWriteRequest = BluetoothRequest.setSpatialAudioMode(.off, operationID: 0x15)
        XCTAssertEqual(spatialOffWriteRequest.toBytes(), [0x55, 0x60, 0x01, 0x52, 0xF0, 0x02, 0x00, 0x15, 0x00, 0x00, 0x05, 0xA9])

        let spatialResponseBytes: [UInt8] = [
            0x55, 0x60, 0x01, 0x4F, 0x40, 0x02, 0x00, 0x0B,
            0x00, 0x00
        ]
        guard let spatialResponse = BluetoothResponse(data: spatialResponseBytes) else {
            XCTFail("Failed to parse spatial audio response")
            return
        }
        XCTAssertEqual(spatialResponse.parseSpatialAudioMode(), .off)
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

    func testInEarDetection() {
        XCTAssertFalse(DeviceModel.headphoneA(.black).supportsInEarDetection)
    }
}
