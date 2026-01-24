import XCTest
@testable import SwiftNothingEar

func assertCustomEQWrite(
    for model: DeviceModel,
    preset: EQPresetCustom,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let specs = model.eqPresetCustomSpecs
    let request = BluetoothRequest.setCustomEQPreset(preset, specs: specs, operationID: 0x01)

    XCTAssertEqual(request.command, BluetoothCommand.RequestWrite.customEQ, file: file, line: line)
    XCTAssertEqual(request.payload.count, 62, file: file, line: line)
    XCTAssertEqual(request.payload.first, 0x03, file: file, line: line)

    let maxGain = max(
        0.0,
        max(Float(preset.bass), max(Float(preset.mid), Float(preset.treble)))
    )
    let expectedTotalGain = -maxGain
    let totalGain = readFloat(from: request.payload, offset: 1)
    XCTAssertEqual(totalGain, expectedTotalGain, accuracy: 0.0001, file: file, line: line)

    let bands = decodeBands(from: request.payload)
    XCTAssertEqual(bands.count, 3, file: file, line: line)

    if bands.count == 3 {
        XCTAssertEqual(bands[0].filterType, 0x01, file: file, line: line)
        XCTAssertEqual(bands[0].gain, Float(preset.mid), accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(bands[0].frequency, specs.freqPeak, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(bands[0].quality, specs.qPeak, accuracy: 0.0001, file: file, line: line)

        XCTAssertEqual(bands[1].filterType, 0x02, file: file, line: line)
        XCTAssertEqual(bands[1].gain, Float(preset.treble), accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(bands[1].frequency, specs.freqHigh, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(bands[1].quality, specs.qHigh, accuracy: 0.0001, file: file, line: line)

        XCTAssertEqual(bands[2].filterType, 0x00, file: file, line: line)
        XCTAssertEqual(bands[2].gain, Float(preset.bass), accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(bands[2].frequency, specs.freqLow, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(bands[2].quality, specs.qLow, accuracy: 0.0001, file: file, line: line)
    }
}

func assertCustomEQRead(
    preset: EQPresetCustom,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let payload = customEQReadPayload(
        bass: Float(preset.bass),
        mid: Float(preset.mid),
        treble: Float(preset.treble)
    )
    let responseBytes = customEQResponseBytes(payload: payload)

    guard let response = BluetoothResponse(data: responseBytes) else {
        XCTFail("Failed to parse custom EQ response", file: file, line: line)
        return
    }

    guard let parsed = response.parseCustomEQPreset() else {
        XCTFail("Failed to parse custom EQ payload", file: file, line: line)
        return
    }

    XCTAssertEqual(parsed.bass, preset.bass, file: file, line: line)
    XCTAssertEqual(parsed.mid, preset.mid, file: file, line: line)
    XCTAssertEqual(parsed.treble, preset.treble, file: file, line: line)
}

private struct EQBandView {
    let filterType: UInt8
    let gain: Float
    let frequency: Float
    let quality: Float
}

private func decodeBands(from payload: [UInt8]) -> [EQBandView] {
    guard payload.count >= 1 + 4 + (3 * 16) else {
        return []
    }

    var bands: [EQBandView] = []
    var offset = 1 + 4

    for _ in 0..<3 {
        let filterType = payload[offset]
        offset += 1

        let gain = readFloat(from: payload, offset: offset)
        offset += 4

        let frequency = readFloat(from: payload, offset: offset)
        offset += 4

        let quality = readFloat(from: payload, offset: offset)
        offset += 4

        bands.append(.init(filterType: filterType, gain: gain, frequency: frequency, quality: quality))
    }

    return bands
}

private func readFloat(from payload: [UInt8], offset: Int) -> Float {
    let raw = UInt32(payload[offset])
        | (UInt32(payload[offset + 1]) << 8)
        | (UInt32(payload[offset + 2]) << 16)
        | (UInt32(payload[offset + 3]) << 24)
    return Float(bitPattern: raw)
}

private func customEQReadPayload(bass: Float, mid: Float, treble: Float) -> [UInt8] {
    var payload = [UInt8](repeating: 0, count: 36)
    writeFloat(bass, into: &payload, offset: 6)
    writeFloat(mid, into: &payload, offset: 19)
    writeFloat(treble, into: &payload, offset: 32)
    return payload
}

private func writeFloat(_ value: Float, into payload: inout [UInt8], offset: Int) {
    let raw = value.bitPattern
    payload[offset] = UInt8(raw & 0xFF)
    payload[offset + 1] = UInt8((raw >> 8) & 0xFF)
    payload[offset + 2] = UInt8((raw >> 16) & 0xFF)
    payload[offset + 3] = UInt8((raw >> 24) & 0xFF)
}

private func customEQResponseBytes(payload: [UInt8]) -> [UInt8] {
    var bytes: [UInt8] = [
        0x55, 0x60, 0x01,
        0x44, 0x40,
        UInt8(payload.count),
        0x00,
        0x01
    ]
    bytes.append(contentsOf: payload)
    return bytes
}
