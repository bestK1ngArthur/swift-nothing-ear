# Nothing X 3.10.0: CMF Speaker Protocol Evidence

Investigation date: 2026-10-13. Source: extracted Android package `com.nothing.smartcenter.apk`, Nothing X 3.10.0.

SHA-256: `d58259729b96b405bb5344800f8f66da57d9050fd285757de9b5f3a3ce3cd60d`.

This describes app-derived protocol support, not hardware validation. jadx reported 373 decompilation errors; the relevant configuration and protocol entities were readable. Real E494/E495 response captures are unavailable, so device-specific response tests skip those captures rather than presenting generated packets as device recordings.

## Model and Feature Evidence

Paths below are relative to the extracted APK or jadx source root.

- `assets/flutter_assets/assets/config/devices_info_list.json`: `E494` / `CMF Speaker S`, `E495` / `CMF Speaker M`, both introduced for Android/iOS app version 3.10.0; color IDs `01`, `02`, `07`, `0C`.
- `assets/flutter_assets/assets/config/ear_tutorial_list.json`: explicit filename labels confirm Orange (`07`), Turquoise (`0C`), and Speaker M Light Gray (`02`). The package uses `.lightGrey` for both speakers; the Speaker S name is inferred from the shared color ID. Color `01` has no speaker-specific label and remains `.color01`. Cloud `skuId` values are not serial number SKU mappings.
- `assets/flutter_assets/assets/config/ear_white_list.json`: speaker `deviceType: 7`, `eq: 31`, `advancedEq: 0`, `earDetection: 0`, `ultraBass: 1`, `spatialAudio: 6`, `supportSoundMode: 1`, `spatialUltraBassExclusive: 1`, and `exclusiveSpaceNightEq: 1`. Custom EQ parameters are 140 Hz / Q 0.8, 980 Hz / Q 0.7, and 3400 Hz / Q 1.
- The same whitelist declares Party/Stereo mode and OTA protocol 5, which the package does not implement. Dual connection changes from disabled to enabled at `*.*.1.49` for Speaker S and `*.*.1.41` for Speaker M; the package does not expose it.

## Implemented Protocol

Speaker requests retain the existing `55 60 01` frame prefix. Queries whose payload would otherwise be empty carry endpoint `[07]`; `07` is not substituted for the frame's type byte. Existing earbud/headphone request encoding remains unchanged.

| Feature | Read / Write | Payload or interpretation |
|---------|--------------|---------------------------|
| Identity / firmware | `0xC006` / `0xC042` | Speaker query endpoint `[07]`; name-based model detection |
| Battery | `0xC007` | Counted component pairs; single level from ID `6`, with ID `7` fallback |
| EQ presets | `0xC01F` / `0xF010` | Balanced `0`, Voice `1`, More Treble `2`, More Bass `3`, Custom `5`; not CMF genre listening modes |
| Custom EQ | `0xC044` / `0xF041` | Three bands using the whitelist frequencies and Q values |
| Ultra Bass | `0xC04E` / `0xF051` | `[enabled, level * 2]`, levels 1–5 |
| Spatial audio | `0xC04F` / `0xF052` | Write one byte: Off `0`, Fixed `1` |
| Sound mode | `0xC072` / `0xF076` | `[mode, minutesLow, minutesHigh]`; Normal `0`, Night `1`; response `0x4072` |
| Gesture | `0xC018` / `0xF003` | `[count, device, button, gesture, action]`; speaker `7`, button `1`, long press `7`, bass toggle `28` or spatial toggle `27` |
| Find My | `0xC002` / `0xF002` | `.unibody` maps to speaker target `7`; write `[07, enabled]` |

Relevant decompiled Java sources include:

- `com/nothing/base/protocol/constant/ProtocolConstant.java`: command IDs, including `GET_XX_MODE_C` / `SET_XX_MODE_C` for sound mode.
- `com/nothing/base/protocol/entity/SoundModeEntity.java`: mode and little-endian auto-off minutes.
- `com/nothing/core/entity/EQModeEntity.java`: standard EQ preset values.
- `com/nothing/earbase/control/entity/ControlConfigurationEntity.java`: control payload and operation identifiers.
- `com/nothing/protocol/model/Message.java` and `com/nothing/protocol/device/TWSDevice.java`: packet construction and device routing.
- `com/nothing/protocol/helper/SpeakerBatteryDisplayFix.java`: app-specific conversion of stereo battery 95 to 100 for configured firmware. The package reports the raw battery level; it does not reproduce this display adjustment.
- `com/nothing/earbase/unknown/UnknownEqExclusiveHelper.java`: EQ exclusivity checks explicitly exclude Balanced (`0`) and Custom (`5`).

The app's controls list makes tap, double press, triple press, and rotation fixed. Only long press is configurable, between bass and spatial toggles; package speaker writes reject other gesture combinations. ANC, in-ear detection, advanced EQ, and low latency are not exposed for speakers.

## Hardware and Transport Limits

Both models declare `isUseGattOverBREDR: 1`. [Apple documents CoreBluetooth GATT over BR/EDR support](https://developer.apple.com/videos/play/wwdc2019/901/), but speaker connection, service selection, and notification delivery remain unverified on both macOS and iOS.

The package scans for `FE2C` and its existing preferred control service `FD90`, and retrieves connected `FD90` peripherals whose names match the speakers. On iOS it also calls `registerForConnectionEvents` for `FD90` to discover paired speakers through connection events. That API is unavailable on macOS, so this additional path is compiled only for iOS. None of these discovery/reconnection paths has been checked against real speakers on either platform.

`com/nothing/caseble/NtStereoPeerBleUuids.java` confirms `FD90` with write characteristic `68745353-1810-4b13-83a2-c1b21b652c9b` and notify characteristic `ca235943-1810-45e6-8326-fc8ca3bc45ce` for an auxiliary stereo-peer API. This does not establish the primary speaker transport UUIDs selected by Flutter; those remain unverified. The package discovers characteristics dynamically.

Voice (`1`), More Treble (`2`), and More Bass (`3`) conflict with Night mode or Fixed spatial audio. `UnknownEqExclusiveHelper` excludes Balanced (`0`) and Custom (`5`) from this EQ interlock. Night mode also conflicts with spatial audio, and spatial audio is exclusive with Ultra Bass. Callers and firmware handle these interlocks; package setters do not automatically change competing modes. Firmware-dependent behavior and auto-off timing still require device testing.
