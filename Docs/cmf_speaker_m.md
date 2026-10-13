# CMF Speaker M

## Device Information

- **Model Code**: `E495`
- **Display / Bluetooth Name**: CMF Speaker M
- **Device Type**: Speaker; command endpoint `0x07`
- **Colors**: `.color01` (color ID `01`, name unverified), `.lightGrey` (`02`), `.orange` (`07`), `.turquoise` (`0C`)
- **Detection**: Bluetooth name; serial SKU mappings are unavailable. Name detection defaults to `.color01` and does not determine the physical color.

Support is derived from Nothing X 3.10.0. No real speaker response captures or Apple-platform hardware connection checks are available. See [protocol evidence and limitations](nothing_x_3_10_0_speakers.md).

## Features

| Feature | Status | Notes |
|---------|--------|-------|
| **Connection / Device Info** | 🟡 | Name recognition and identity/firmware requests; `FE2C`/`FD90` discovery and iOS connection events; GATT transport needs hardware verification |
| **Battery Status** | 🟡 | Single battery; prefer component `6`, fall back to `7` |
| **Equalizer Presets** | 🟡 | Balanced, Voice, More Treble, More Bass, Custom; standard EQ commands |
| **Custom Equalizer** | 🟡 | Three bands at 140/980/3400 Hz |
| **Ultra Bass** | 🟡 | Read/write; levels 1–5 |
| **Spatial Audio** | 🟡 | Off / Fixed; one-byte write; mutually exclusive with Ultra Bass |
| **Sound Mode** | 🟡 | Normal / Night with auto-off duration in minutes |
| **Gesture Controls** | 🟡 | Configure speaker long press to toggle bass boost or spatial audio; other physical controls are fixed |
| **Find My Speaker** | 🟡 | Use `RingBuds` with `.unibody`; speaker target is `0x07` |
| **Active Noise Cancellation** | ⚫ | Not supported by speaker feature set |
| **In-Ear Detection** | ⚫ | Not supported |
| **Low Latency Mode** | ⚫ | Not exposed; no support evidence in the 3.10.0 speaker configuration |
| **Advanced Equalizer** | ⚫ | Not supported |
| **Party / Stereo Mode** | 🔴 | Present in app configuration; not implemented by package |
| **Dual Connection** | 🔴 | App enables it from firmware `*.*.1.41`; not implemented by package |
| **Firmware Update** | 🔴 | App OTA protocol exists; not implemented by package |

Voice, More Treble, and More Bass presets conflict with Night mode or Fixed spatial audio; Balanced and Custom do not trigger this EQ interlock. Night mode also conflicts with spatial audio, and spatial audio conflicts with Ultra Bass. The caller and device handle these interlocks; package setters do not change other modes automatically.

- 🟡 Source-derived implementation; hardware verification and captured responses needed
- 🔴 Not implemented by package
- ⚫ Not supported by speaker feature set
