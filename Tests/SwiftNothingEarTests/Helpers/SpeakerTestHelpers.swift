import XCTest
@testable import SwiftNothingEar

// Synthetic protocol fixtures. No hardware capture is implied.
private func speakerResponse(_ command: UInt16, _ payload: [UInt8]) -> BluetoothResponse? {
    BluetoothResponse(data: [
        0x55, 0x60, 0x01, UInt8(command & 0xFF), UInt8(command >> 8),
        UInt8(payload.count), 0x00, 0x01
    ] + payload)
}

func assertSpeakerResponseLayouts(
    for model: DeviceModel,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    for command in [BluetoothCommand.Response.batteryA, BluetoothCommand.Response.batteryB] {
        for (payload, expectedLevel, charging, connected) in [
            ([UInt8(1), 7, 0xD8], 88, true, true),
            ([1, 6, 0], 0, false, true),
            ([2, 7, 50, 6, 75], 75, false, true),
            ([1, 7, 0xFF], 0, false, false),
            ([0], 0, false, false)
        ] {
            let response = try XCTUnwrap(speakerResponse(command, payload), file: file, line: line)
            guard case .single(let level) = response.parseBattery(model: model) else {
                XCTFail("Speaker battery must be a single unit", file: file, line: line)
                continue
            }
            XCTAssertEqual(level.level, expectedLevel, file: file, line: line)
            XCTAssertEqual(level.isCharging, charging, file: file, line: line)
            XCTAssertEqual(level.isConnected, connected, file: file, line: line)
        }
        XCTAssertNil(speakerResponse(command, [2, 7, 50])?.parseBattery(model: model), file: file, line: line)
    }

    XCTAssertEqual(speakerResponse(0x401F, [3])?.parseEQPreset(for: model), .moreBass, file: file, line: line)
    let bass = try XCTUnwrap(speakerResponse(0x404E, [1, 6])?.parseEnhancedBassSettings(), file: file, line: line)
    XCTAssertTrue(bass.isEnabled, file: file, line: line)
    XCTAssertEqual(bass.level, 3, file: file, line: line)
    XCTAssertEqual(speakerResponse(0x404F, [1])?.parseSpatialAudioMode(), .fixed, file: file, line: line)
    XCTAssertEqual(speakerResponse(0x404F, [0])?.parseSpatialAudioMode(), .off, file: file, line: line)

    let gestures = try XCTUnwrap(speakerResponse(0x4018, [1, 7, 1, 7, 28]), file: file, line: line).parseGestures()
    XCTAssertEqual(gestures.count, 1, file: file, line: line)
    XCTAssertEqual(gestures.first?.device, .speaker, file: file, line: line)
    XCTAssertEqual(gestures.first?.type, .longPress, file: file, line: line)
    XCTAssertEqual(gestures.first?.action, .bassBoostToggle, file: file, line: line)
    XCTAssertEqual(speakerResponse(0x4018, [1, 7, 1, 7, 27])?.parseGestures().first?.action,
                   .spatialAudioToggle, file: file, line: line)
    let ring = try XCTUnwrap(speakerResponse(0x4002, [1, 7, 1])?.parseRingBuds(), file: file, line: line)
    XCTAssertEqual(ring.bud, .unibody, file: file, line: line)
    XCTAssertTrue(ring.isOn, file: file, line: line)
    XCTAssertEqual(speakerResponse(0x4072, [1, 44, 1])?.parseSpeakerSoundMode(),
                   .night(autoOffMinutes: 300), file: file, line: line)
    XCTAssertEqual(speakerResponse(0x4072, [0, 0, 0])?.parseSpeakerSoundMode(), .normal, file: file, line: line)
    for payload: [UInt8] in [[1], [1, 44]] {
        XCTAssertEqual(speakerResponse(0x4072, payload)?.parseSpeakerSoundMode(),
                       .night(autoOffMinutes: 0), file: file, line: line)
    }
    XCTAssertEqual(speakerResponse(0x4072, [0])?.parseSpeakerSoundMode(), .normal, file: file, line: line)
    XCTAssertNil(speakerResponse(0x4072, [])?.parseSpeakerSoundMode(), file: file, line: line)
    XCTAssertNil(speakerResponse(0x4072, [2, 0, 0])?.parseSpeakerSoundMode(), file: file, line: line)
    assertCustomEQRead(preset: .init(bass: 6, mid: 0, treble: -3), file: file, line: line)

    let configuration = [UInt8(1)] + Array("7,4,unmapped-speaker-serial\n".utf8)
    let identity = try XCTUnwrap(speakerResponse(0x4006, configuration)?.parseDeviceIdentity(
        deviceName: model.displayName
    ), file: file, line: line)
    XCTAssertEqual(identity.model, model, file: file, line: line)
    XCTAssertEqual(identity.serialNumber, "unmapped-speaker-serial", file: file, line: line)
    XCTAssertEqual(speakerResponse(0x4042, Array("1.0.1.49".utf8))?.parseFirmwareVersion(),
                   "1.0.1.49", file: file, line: line)
}

@MainActor
func assertSpeakerSoundModeCallback(
    for model: DeviceModel,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    var reportedModes: [SpeakerSoundMode?] = []
    let callback = Callback(
        onDiscover: { _ in }, onConnect: { _ in }, onDisconnect: { _ in },
        onUpdateBattery: { _ in }, onUpdateANCMode: { _ in },
        onUpdateSpatialAudio: { _ in }, onUpdateEnhancedBass: { _ in },
        onUpdateEQPreset: { _ in }, onUpdateDeviceSettings: { _ in },
        onUpdateRingBuds: { _ in },
        onUpdateSpeakerSoundMode: { reportedModes.append($0) }, onError: { _ in }
    )
    let device = Device(callback, initializesBluetooth: false)
    // A prior connection/override must not suppress the new speaker's handshake endpoint.
    device.setEffectiveModelOverride(.earA(.black))
    let query = BluetoothRequest(command: BluetoothCommand.RequestRead.serialNumber, payload: [], operationID: 1)
    XCTAssertEqual(device.requestBytes(query, deviceName: model.displayName),
                   query.toBytes(for: model), file: file, line: line)
    device.setEffectiveModelOverride(model)
    // Conversely, a retained speaker model must not leak endpoint 7 into a new earbud handshake.
    XCTAssertEqual(device.requestBytes(query, deviceName: "Nothing Ear (a)"),
                   query.toBytes(for: .earA(.black)), file: file, line: line)
    device.processResponse(Data([0x55, 0x60, 1, 0x72, 0x40, 3, 0, 1, 1, 44, 1]))
    XCTAssertEqual(device.speakerSoundMode, .night(autoOffMinutes: 300), file: file, line: line)
    XCTAssertEqual(reportedModes, [.night(autoOffMinutes: 300)], file: file, line: line)

    device.setEffectiveModelOverride(.earA(.black))
    device.processResponse(Data([0x55, 0x60, 1, 0x72, 0x40, 3, 0, 1, 0, 0, 0]))
    XCTAssertEqual(reportedModes.count, 1, file: file, line: line)
}
