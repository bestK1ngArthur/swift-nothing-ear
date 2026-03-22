# Agent Guidelines

Swift package for communicating with Nothing and CMF audio devices over Bluetooth on macOS and iOS.

## Structure

```
Sources/SwiftNothingEar/
  Device.swift              # Public entry point — scanning, connecting, commands
  DeviceModel.swift         # All supported models, serial/name detection, capability flags
  DeviceInfo.swift          # Info returned on connect (model, serial, firmware)
  DeviceSettings.swift      # In-ear detection, low latency
  Bluetooth.swift           # Raw BLE protocol — request/response encoding, CRC
  DeviceCapability/
    Battery.swift
    NoiseCancellation.swift
    EQ.swift
    EnhancedBass.swift
    Gesture.swift
    SpatialAudio.swift
    RingBuds.swift

Tests/SwiftNothingEarTests/
  <ModelName>Tests.swift    # One file per device model
  Helpers/
    CustomEQTestHelpers.swift
```

## Adding a New Device Model

1. Add a case to `DeviceModel` in `DeviceModel.swift`
2. Add Bluetooth name matching in `getModel(for:serialNumber:)`
3. Add serial number SKU mappings in `getModel(fromSKU:)`
4. Update capability conformances (`isSupported(by:)`) in each `DeviceCapability/` file
5. Add a device doc in `Docs/<model>.md`
6. Add the model to the Supported Devices list in `README.md`
7. **Write a dedicated test file** `Tests/SwiftNothingEarTests/<ModelName>Tests.swift`

## Testing Rules

**Every device model must have its own test file.** Tests cover the raw Bluetooth protocol — byte-level request encoding and response parsing — so they catch regressions across firmware variants without requiring hardware.

Each model test file should cover every feature the model supports:

- `testBattery()` — request bytes + response parsing (single or budsWithCase)
- `testANC()` — read request, write request, response parsing (if model supports ANC)
- `testEQPreset()` — read request, write request, response parsing (if model supports EQ)
- `testEnhancedBass()` — read + write requests, response parsing (if supported)
- `testGestures()` — read + write requests, response parsing (if supported)
- `testInEarDetection()` — read + write requests, response parsing
- `testLowLatency()` — read + write requests, response parsing
- `testRingBuds()` — read + write requests, response parsing (if supported)
- `testSpatialAudio()` — read + write requests, response parsing (if supported)
- `testCustomEQPreset()` — uses `CustomEQTestHelpers` (if model supports custom EQ)
- `testModelDetectionByNameAndSerial()` — all serial SKUs and Bluetooth names for the model

Use real captured byte sequences from the actual device. If bytes are unavailable, mark the test as `XCTSkip` with a note rather than omitting it.

Test structure follows the existing files — see `NothingEarATests.swift` for reference.

## Key Conventions

- `BluetoothRequest` / `BluetoothResponse` are the only types that touch raw bytes. Keep protocol logic inside `Bluetooth.swift`.
- Capability support is declared statically via `DeviceCapability.isSupported(by:)` — check this before adding feature-specific code.
- `Device` is `@MainActor`. Keep all public API on the main actor.
- No third-party dependencies.
