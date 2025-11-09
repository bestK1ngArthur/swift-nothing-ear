# swift-nothing-ear

> It's unofficial software and not affilated with Nothing ([legal](#legal-disclaimer))

Swift Package for interacting with Nothing headphones on macOS and iOS.

Special credits to:

> Ear (web) project developers for bluetooth communication code, it has been really helpful in developing this project. Link to Ear (web): https://earweb.bttl.xyz

- 🟢 _works and tested_
- 🟡 _may work, but support is still in process_

## Supported Devices

- 🟡 [Nothing Ear (1)](Docs/ear_1.md)
- 🟡 [Nothing Ear (2)](Docs/ear_2.md)
- 🟡 [Nothing Ear (3)](Docs/ear_3.md)
- 🟡 [Nothing Ear (stick)](Docs/ear_stick.md)
- 🟡 [Nothing Ear (open)](Docs/ear_open.md)
- 🟡 [Nothing Ear](Docs/ear.md)
- 🟡 [Nothing Ear (a)](Docs/ear_a.md)
- 🟢 [Nothing Headphone (1)](Docs/headphones_1.md)
- 🟡 [CMF Buds Pro](Docs/cmf_buds_pro.md)
- 🟡 [CMF Buds](Docs/cmf_buds.md)
- 🟡 [CMF Buds Pro 2](Docs/cmf_buds_pro_2.md)
- 🟡 [CMF Neckband Pro](Docs/cmf_neckband_pro.md)
- 🟡 [CMF Headphone Pro](Docs/cmf_headphone_pro.md)

## Installation

### Swift Package Manager

Add dependency to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bestK1ngArthur/swift-nothing-ear.git", from: "1.0.0")
]
```

Or via Xcode: File → Add Package Dependencies and enter the repository URL.

### Add Permissions

Add to `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>The app requires Bluetooth to connect to Nothing earbuds</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>The app requires Bluetooth to connect to Nothing earbuds</string>
```

## Quick Start

```swift
import SwiftNothingEar

@MainActor
class ViewController: UIViewController {
    private var nothingEarDevice: NothingEar.Device!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create device with callbacks
        nothingEarDevice = NothingEar.Device(
            NothingEar.Callback(
                onDiscover: { peripheral in
                    print("Discovered device: \(peripheral.name ?? "Unknown")")
                },
                onConnect: { result in
                    switch result {
                    case .success(let deviceInfo):
                        print("Connected to \(deviceInfo.model.displayName)")
                        print("Serial: \(deviceInfo.serialNumber)")
                        if let firmware = deviceInfo.firmwareVersion {
                            print("Firmware: \(firmware)")
                        }
                    case .failure(let error):
                        print("Connection failed: \(error)")
                    }
                },
                onDisconnect: { result in
                    switch result {
                    case .success:
                        print("Device disconnected")
                    case .failure(let error):
                        print("Disconnection error: \(error)")
                    }
                },
                onUpdateBattery: { battery in
                    if let battery = battery {
                        switch battery {
                        case .single(let level):
                            print("Battery: \(level.level)%")
                        case .budsWithCase(let caseLevel, let leftBud, let rightBud):
                            print("Battery - Case: \(caseLevel.level)%, Left: \(leftBud.level)%, Right: \(rightBud.level)%")
                        }
                    }
                },
                onUpdateANCMode: { ancMode in
                    if let ancMode = ancMode {
                        print("ANC mode: \(ancMode.displayName)")
                    }
                },
                onUpdateEnhancedBass: { enhancedBass in
                    if let enhancedBass = enhancedBass {
                        print("Enhanced Bass: \(enhancedBass.isEnabled ? "enabled" : "disabled"), level: \(enhancedBass.level)")
                    }
                },
                onUpdateEQPreset: { eqPreset in
                    if let eqPreset = eqPreset {
                        print("EQ preset: \(eqPreset.displayName)")
                    }
                },
                onUpdateDeviceSettings: { settings in
                    print("In-ear detection: \(settings.inEarDetection)")
                    print("Low latency: \(settings.lowLatency)")
                },
                onError: { error in
                    print("Error: \(error.localizedDescription)")
                }
            )
        )
    }
}
```

## Working with Already Connected Devices

The library automatically detects and connects to Nothing Ear devices that are already connected via Bluetooth:

### Manual Check for Connected Devices

```swift
// Check and connect to existing devices
if nothingEarDevice.checkAndConnectToExistingDevices() {
    print("Found and connecting to existing device...")
} else {
    print("No existing devices found, starting scan...")
    nothingEarDevice.startScanning()
}
```

### Connection States

The device provides detailed connection states including when existing devices are found:

```swift
// Check connection status
switch nothingEarDevice.connectionStatus {
case .disconnected:
    print("Device is disconnected")
case .scanning:
    print("Scanning for devices")
case .connecting:
    print("Connecting to device")
case .connected:
    print("Connected to device")
case .foundConnected:
    print("Found already connected device")
}

// Check if device is connected and ready
if nothingEarDevice.isConnected {
    print("Device is ready for commands")
}
```

## Detailed Usage

### ANC Mode Control

```swift
// Check ANC support based on device model
if let deviceInfo = nothingEarDevice.deviceInfo,
   deviceInfo.model.supportsANC {
    
    // Set noise cancellation modes
    nothingEarDevice.setANCMode(.noiseCancellation(.high))
    nothingEarDevice.setANCMode(.noiseCancellation(.adaptive))
    
    // Transparency mode
    nothingEarDevice.setANCMode(.transparent)
    
    // Turn off ANC
    nothingEarDevice.setANCMode(.off)
}
```

### Equalizer Settings

```swift
// Set preset EQ
nothingEarDevice.setEQPreset(.balanced)
nothingEarDevice.setEQPreset(.moreBass)
nothingEarDevice.setEQPreset(.voice)
nothingEarDevice.setEQPreset(.moreTreble)
nothingEarDevice.setEQPreset(.custom)
```

### Gesture Control

```swift
// Double tap left earbud for play/pause
nothingEarDevice.setGesture(
    type: .doubleTap,
    action: .playPause,
    device: .left
)

// Long press right earbud for voice assistant
nothingEarDevice.setGesture(
    type: .longPress,
    action: .voiceAssistant,
    device: .right
)

// Triple tap for next track
nothingEarDevice.setGesture(
    type: .trippleTap,
    action: .nextTrack,
    device: .right
)
```

### Enhanced Bass Settings

```swift
// Check enhanced bass support
if let deviceInfo = nothingEarDevice.deviceInfo,
   deviceInfo.model.supportsEnhancedBass {
    
    // Enable enhanced bass with level 50
    let bassSettings = NothingEar.EnhancedBassSettings(isEnabled: true, level: 50)
    nothingEarDevice.setEnhancedBass(bassSettings)
    
    // Disable enhanced bass
    let disabledBass = NothingEar.EnhancedBassSettings(isEnabled: false, level: 0)
    nothingEarDevice.setEnhancedBass(disabledBass)
}
```

### Other Settings

```swift
// Enable in-ear detection
nothingEarDevice.setInEarDetection(true)

// Enable low latency mode
nothingEarDevice.setLowLatency(true)
```

### Check Supported Features

```swift
// Check device model capabilities
if let deviceInfo = nothingEarDevice.deviceInfo {
    let model = deviceInfo.model
    
    print("Device: \(model.displayName)")
    print("✅ ANC Support: \(model.supportsANC)")
    print("✅ Custom EQ Support: \(model.supportsCustomEQ)")
    print("✅ Enhanced Bass Support: \(model.supportsEnhancedBass)")
    print("✅ In-Ear Detection Support: \(model.supportsInEarDetection)")
}

// Access current device state
if let battery = nothingEarDevice.battery {
    print("Current battery: \(battery)")
}

if let ancMode = nothingEarDevice.ancMode {
    print("Current ANC mode: \(ancMode.displayName)")
}

if let eqPreset = nothingEarDevice.eqPreset {
    print("Current EQ preset: \(eqPreset.displayName)")
}

if let settings = nothingEarDevice.deviceSettings {
    print("In-ear detection: \(settings.inEarDetection)")
    print("Low latency: \(settings.lowLatency)")
}
```

## Error Handling Examples

```swift
// Handle errors in callback
nothingEarDevice = NothingEar.Device(
    NothingEar.Callback(
        // ... other callbacks ...
        onError: { error in
            switch error {
            case .bluetoothUnavailable:
                showAlert("Bluetooth unavailable")
            case .deviceNotFound:
                showAlert("Device not found")
            case .connectionFailed:
                showAlert("Failed to connect")
            case .unsupportedOperation:
                showAlert("Operation not supported by this model")
            case .timeout:
                showAlert("Operation timed out")
            case .invalidResponse:
                showAlert("Invalid response from device")
            }
        }
    )
)
```

## Legal Disclaimer

1. This software is not affiliated with, sponsored by, or endorsed by Nothing Technology. This software is a third-party project and is NOT an official Nothing product.

2. Nothing, the Nothing logo and other brand related content are trademarks of Nothing Technology Limited and are protected by copyright, trademark, and other intellectual property laws.

3. You use this software at your own risk. The developer makes no warranties regarding compatibility with all firmware versions, performance, or reliability. 

4. The developer shall not be liable for any direct or indirect damages arising from the use of the software, including data loss, hardware damage, or degraded audio quality. 

5. By installing and using this software, you agree to the terms of this disclaimer.

If you have questions, [contact me](mailto:bestk1ngarthur@aol.com).
