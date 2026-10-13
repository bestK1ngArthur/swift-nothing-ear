import XCTest
@testable import SwiftNothingEar

final class CMFSpeakerSTests: XCTestCase {
    private let model = DeviceModel.cmfSpeakerS(.color01)

    func testModelDetectionByNameAndSerial() {
        XCTAssertEqual(model.displayName, "CMF Speaker S")
        XCTAssertEqual(model.code, "E494")
        XCTAssertTrue(model.isCMF)
        XCTAssertTrue(model.isSpeaker)
        for serial in ["", "unmapped-speaker-serial", "SH002501000000"] {
            XCTAssertEqual(DeviceModel.getModel(for: "CMF Speaker S", serialNumber: serial), model)
        }
        XCTAssertTrue(DeviceModel.isBaseEqual(lhs: model, rhs: .cmfSpeakerS(.turquoise)))
        XCTAssertFalse(DeviceModel.isBaseEqual(lhs: model, rhs: .cmfSpeakerM(.color01)))
    }

    func testSerialSKUMappings() throws {
        throw XCTSkip("Captured CMF Speaker S serial SKU mappings are not available.")
    }

    func testCapabilities() {
        let models: [DeviceModel] = [
            .cmfSpeakerS(.color01), .cmfSpeakerS(.lightGrey),
            .cmfSpeakerS(.orange), .cmfSpeakerS(.turquoise)
        ]
        for model in models {
            XCTAssertTrue(model.supportsEQ)
            XCTAssertTrue(model.supportsCustomEQ)
            XCTAssertTrue(model.supportsEnhancedBass)
            XCTAssertTrue(model.supportsSpatialAudio)
            XCTAssertTrue(model.supportsRingBuds)
            XCTAssertTrue(model.supportsSpeakerSoundMode)
            XCTAssertFalse(model.supportsNoiseCancellation)
            XCTAssertFalse(model.supportsInEarDetection)
            XCTAssertFalse(model.supportsLowLatency)
            XCTAssertFalse(model.supportsListeningMode)
            XCTAssertEqual(EQPreset.allSupported(by: model), [.balanced, .voice, .moreTreble, .moreBass, .custom])
            XCTAssertEqual(SpatialAudioMode.allSupported(by: model), [.off, .fixed])
            XCTAssertFalse(SpatialAudioMode.isCompatibleWithEnhancedBass(by: model))
            XCTAssertEqual(NoiseCancellationMode.allSupported(by: model), [])
        }
        XCTAssertFalse(DeviceModel.earA(.black).supportsSpeakerSoundMode)
        XCTAssertTrue(DeviceModel.earA(.black).supportsLowLatency)
    }

    // Request fixtures below are source-derived, not hardware captures.
    func testInitialQueriesUseSpeakerEndpoint() {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.serialNumber),
            [0x55, 0x60, 0x01, 0x06, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x9E, 0x92])
        XCTAssertEqual(read(BluetoothCommand.RequestRead.firmware),
            [0x55, 0x60, 0x01, 0x42, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x91, 0xD6])
        let query = BluetoothRequest(command: BluetoothCommand.RequestRead.battery, payload: [0x07], operationID: 1)
        XCTAssertEqual(query.toBytes(for: model), query.toBytes())
        // Existing earbud packets retain an empty payload.
        XCTAssertEqual(BluetoothRequest(command: BluetoothCommand.RequestRead.battery, payload: [], operationID: 1)
            .toBytes(for: .earA(.black)), [0x55, 0x60, 0x01, 0x07, 0xC0, 0x00, 0x00, 0x01, 0xAC, 0xDF])
    }

    func testBattery() throws {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.battery),
            [0x55, 0x60, 0x01, 0x07, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x9F, 0x43])
        throw XCTSkip("Captured CMF Speaker S battery response bytes are not available.")
    }

    func testEQPreset() throws {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.eq),
            [0x55, 0x60, 0x01, 0x1F, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x9C, 0x9B])
        XCTAssertEqual(BluetoothRequest.setEQPreset(.moreBass, for: model, operationID: 1)?.toBytes(for: model),
            [0x55, 0x60, 0x01, 0x10, 0xF0, 0x02, 0x00, 0x01, 0x03, 0x00, 0x27, 0x59])
        XCTAssertNil(BluetoothRequest.setEQPreset(.advanced, for: model, operationID: 1))
        XCTAssertNil(BluetoothRequest.setEQPreset(.rock, for: model, operationID: 1))
        throw XCTSkip("Captured CMF Speaker S EQ response bytes are not available.")
    }

    func testEnhancedBass() throws {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.enhancedBass),
            [0x55, 0x60, 0x01, 0x4E, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x91, 0x1A])
        XCTAssertEqual(BluetoothRequest.setEnhancedBass(.init(isEnabled: true, level: 3), operationID: 1).toBytes(for: model),
            [0x55, 0x60, 0x01, 0x51, 0xF0, 0x02, 0x00, 0x01, 0x01, 0x06, 0xF7, 0x3F])
        throw XCTSkip("Captured CMF Speaker S Ultra Bass response bytes are not available.")
    }

    func testSpatialAudio() throws {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.spatialAudio),
            [0x55, 0x60, 0x01, 0x4F, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x90, 0xCB])
        XCTAssertEqual(BluetoothRequest.setSpatialAudioMode(.fixed, for: model, operationID: 1).toBytes(for: model),
            [0x55, 0x60, 0x01, 0x52, 0xF0, 0x01, 0x00, 0x01, 0x01, 0x53, 0x40])
        XCTAssertEqual(BluetoothRequest.setSpatialAudioMode(.off, for: model, operationID: 1).toBytes(for: model),
            [0x55, 0x60, 0x01, 0x52, 0xF0, 0x01, 0x00, 0x01, 0x00, 0x92, 0x80])
        throw XCTSkip("Captured CMF Speaker S spatial audio response bytes are not available.")
    }

    func testGestures() throws {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.gesture),
            [0x55, 0x60, 0x01, 0x18, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x9D, 0x2C])
        XCTAssertEqual(BluetoothRequest.setGesture(.init(type: .longPress, action: .bassBoostToggle, device: nil),
            for: model, operationID: 1).toBytes(for: model),
            [0x55, 0x60, 0x01, 0x03, 0xF0, 0x05, 0x00, 0x01, 0x01, 0x07, 0x01, 0x07, 0x1C, 0x10, 0xAA])
        XCTAssertEqual(BluetoothRequest.setGesture(.init(type: .longPress, action: .spatialAudioToggle, device: .speaker),
            for: model, operationID: 1).toBytes(for: model),
            [0x55, 0x60, 0x01, 0x03, 0xF0, 0x05, 0x00, 0x01, 0x01, 0x07, 0x01, 0x07, 0x1B, 0x51, 0x68])
        throw XCTSkip("Captured CMF Speaker S gesture response bytes are not available.")
    }

    func testOnlySpeakerHoldActionsAreWritable() {
        XCTAssertTrue(Gesture(type: .longPress, action: .bassBoostToggle, device: nil).isWritable(for: model))
        XCTAssertTrue(Gesture(type: .longPress, action: .spatialAudioToggle, device: .speaker).isWritable(for: model))
        XCTAssertFalse(Gesture(type: .tap, action: .playPause, device: .speaker).isWritable(for: model))
        XCTAssertFalse(Gesture(type: .longPress, action: .ancToggle, device: .speaker).isWritable(for: model))
        XCTAssertFalse(Gesture(type: .longPress, action: .bassBoostToggle, device: .left).isWritable(for: model))
        XCTAssertFalse(Gesture(type: .longPress, action: .customAction, device: nil).isWritable(for: model))
        XCTAssertFalse(Gesture(type: .longPress, action: .bassBoostToggle, device: nil).isWritable(for: .ear1(.black)))
        XCTAssertFalse(Gesture(type: .longPress, action: .spatialAudioToggle, device: nil).isWritable(for: .earStick))
    }

    func testRingBuds() throws {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.ringBuds),
            [0x55, 0x60, 0x01, 0x02, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x9F, 0x16])
        XCTAssertEqual(BluetoothRequest.setRingBuds(.init(isOn: true, bud: .unibody), for: model, operationID: 1).toBytes(for: model),
            [0x55, 0x60, 0x01, 0x02, 0xF0, 0x02, 0x00, 0x01, 0x07, 0x01, 0xD6, 0x58])
        throw XCTSkip("Captured CMF Speaker S Find My response bytes are not available.")
    }

    func testCustomEQPreset() throws {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.customEQ),
            [0x55, 0x60, 0x01, 0x44, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x91, 0xB0])
        let specs = model.eqPresetCustomSpecs
        XCTAssertEqual(specs.freqLow, 140)
        XCTAssertEqual(specs.qLow, 0.8)
        XCTAssertEqual(specs.freqPeak, 980)
        XCTAssertEqual(specs.qPeak, 0.7)
        XCTAssertEqual(specs.freqHigh, 3400)
        XCTAssertEqual(specs.qHigh, 1)
        assertCustomEQWrite(for: model, preset: .init(bass: 6, mid: 0, treble: -3))
        throw XCTSkip("Captured CMF Speaker S custom EQ response bytes are not available.")
    }

    func testSpeakerSoundMode() throws {
        XCTAssertEqual(read(BluetoothCommand.RequestRead.speakerSoundMode),
            [0x55, 0x60, 0x01, 0x72, 0xC0, 0x01, 0x00, 0x01, 0x07, 0x94, 0x26])
        XCTAssertEqual(BluetoothRequest.setSpeakerSoundMode(.night(autoOffMinutes: 300), operationID: 1).toBytes(for: model),
            [0x55, 0x60, 0x01, 0x76, 0xF0, 0x03, 0x00, 0x01, 0x01, 0x2C, 0x01, 0xE2, 0x09])
        XCTAssertEqual(BluetoothRequest.setSpeakerSoundMode(.normal, operationID: 1).toBytes(for: model),
            [0x55, 0x60, 0x01, 0x76, 0xF0, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x6E, 0xC9])
        throw XCTSkip("Captured CMF Speaker S night mode response bytes are not available.")
    }

    func testInEarDetection() {
        XCTAssertFalse(model.supportsInEarDetection)
    }

    func testLowLatency() {
        XCTAssertFalse(model.supportsLowLatency)
    }

    func testSourceDerivedResponseLayouts() throws {
        // These synthetic payloads test the native parsers' layouts, not device compatibility.
        try assertSpeakerResponseLayouts(for: model)
    }

    @MainActor
    func testSpeakerSoundModeUpdatesDeviceStateAndCallback() {
        assertSpeakerSoundModeCallback(for: model)
    }

    private func read(_ command: UInt16) -> [UInt8] {
        BluetoothRequest(command: command, payload: [], operationID: 1).toBytes(for: model)
    }
}
