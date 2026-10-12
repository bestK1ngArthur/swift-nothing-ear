# Nothing Headphone (a)

## Device Information

- **Model Code**: `B186` (`B198` variant also exists)
- **Display Name**: Nothing Headphone (a)
- **Device Type**: Full-size headphones
- **Colors**: Black, White, Yellow, Pink

## Features

| Feature | Status | Notes |
|---------|---------------|-------------|
| **Connection** | 🟢 | Bluetooth connection and device discovery |
| **Device Info** | 🟢 | Read serial number, firmware version, bluetooth address |
| **Battery Status** | 🟢 | Read battery level and charging status |
| **Active Noise Cancellation** | 🟢 | Read and change mode; receive mode-change notifications (`0x6003`) |
| **Spatial Audio** | 🟢 | Read and change static modes: Off, Cinema, Concert; no head tracking |
| **Enhanced Bass** | 🟢 | Read/write and level changing (on/off, level 1-5) |
| **Equalizer Presets** | 🟡 | Read and set all EQ presets without advanced settings |
| **Gesture Controls** | 🔴 | Supported by device, but not implemented by this package |
| **In-Ear Detection** | ⚫ | Not supported by device |
| **Personalized ANC** | ⚫ | Not supported by device |
| **Low Lag Mode** | 🟢 | Read and set |
| **Find My Earbuds** | 🟢 | Read and set |
| **High Quality Audio** | ⚫ | Not supported by device |

- 🟢 Supported
- 🟡 Partially supported
- 🔴 Not supported by package
- ⚫ Not supported by device

## Spatial Audio and Protocol Tests

Nothing describes Headphone (a) as supporting [Static Spatial Audio](https://us.nothing.tech/products/headphone-a) with concert and cinema effects, without head tracking.

Tests use captured ANC notifications for Adaptive, Off, and Transparency, and verify that they update device state and invoke the ANC callback. Spatial Audio captures cover writes for Off, Cinema, and Concert, and a read response for Off. Read-response tests for Cinema and Concert are skipped until captures from Headphone (a) are available.
