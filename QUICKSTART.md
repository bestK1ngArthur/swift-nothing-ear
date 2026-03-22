# Quick Start

## Basic Setup

```swift
import SwiftNothingEar

@MainActor
class ViewController: UIViewController {
    private var nothingEarDevice: Device!

    override func viewDidLoad() {
        super.viewDidLoad()

        nothingEarDevice = Device(
            Callback(
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
                    guard let battery else { return }
                    switch battery {
                    case .single(let level):
                        print("Battery: \(level.level)%")
                    case .budsWithCase(let caseLevel, let leftBud, let rightBud):
                        print("Battery — Case: \(caseLevel.level)%, Left: \(leftBud.level)%, Right: \(rightBud.level)%")
                    }
                },
                onUpdateANCMode: { ancMode in
                    if let ancMode {
                        print("ANC mode: \(ancMode.displayName)")
                    }
                },
                onUpdateSpatialAudio: { spatialAudio in
                    if let spatialAudio {
                        print("Spatial audio: \(spatialAudio)")
                    }
                },
                onUpdateEnhancedBass: { enhancedBass in
                    if let enhancedBass {
                        print("Enhanced Bass: \(enhancedBass.isEnabled ? "enabled" : "disabled"), level: \(enhancedBass.level)")
                    }
                },
                onUpdateEQPreset: { eqPreset in
                    if let eqPreset {
                        print("EQ preset: \(eqPreset.displayName)")
                    }
                },
                onUpdateDeviceSettings: { settings in
                    print("In-ear detection: \(settings.inEarDetection)")
                    print("Low latency: \(settings.lowLatency)")
                },
                onUpdateRingBuds: { ringBuds in
                    print("Ring buds: \(ringBuds)")
                },
                onError: { error in
                    print("Error: \(error.localizedDescription)")
                }
            )
        )

        nothingEarDevice.startScanning()
    }
}
```

## Scanning and Connection

`startScanning()` first checks for already-connected Nothing devices and connects automatically. You can also manage this manually:

```swift
// Start scanning (checks existing connections first)
nothingEarDevice.startScanning()

// Or manually check for already-connected devices
if nothingEarDevice.checkAndConnectToExistingDevices() {
    print("Found and connecting to existing device...")
} else {
    print("No existing devices found, starting scan...")
    nothingEarDevice.startScanning()
}

// Stop scanning
nothingEarDevice.stopScanning()
```

### Connection Status

```swift
switch nothingEarDevice.connectionStatus {
case .disconnected:
    print("Disconnected")
case .scanning:
    print("Scanning for devices")
case .connecting:
    print("Connecting to device")
case .connected:
    print("Connected")
case .foundConnected:
    print("Found already-connected device")
}

if nothingEarDevice.isConnected {
    print("Device is ready for commands")
}
```

## ANC Mode

```swift
if let deviceInfo = nothingEarDevice.deviceInfo,
   NoiseCancellationMode.isSupported(by: deviceInfo.model) {

    nothingEarDevice.setANCMode(.active(.high))
    nothingEarDevice.setANCMode(.active(.adaptive))
    nothingEarDevice.setANCMode(.transparent)
    nothingEarDevice.setANCMode(.off)
}
```

## Equalizer

```swift
nothingEarDevice.setEQPreset(.balanced)
nothingEarDevice.setEQPreset(.moreBass)
nothingEarDevice.setEQPreset(.moreTreble)
nothingEarDevice.setEQPreset(.voice)
nothingEarDevice.setEQPreset(.custom)
```

## Gesture Control

```swift
// Double-tap left earbud — play/pause
nothingEarDevice.setGesture(type: .doubleTap, action: .playPause, device: .left)

// Long-press right earbud — voice assistant
nothingEarDevice.setGesture(type: .longPress, action: .voiceAssistant, device: .right)

// Triple-tap right earbud — next track
nothingEarDevice.setGesture(type: .trippleTap, action: .nextTrack, device: .right)
```

## Enhanced Bass

```swift
if let deviceInfo = nothingEarDevice.deviceInfo,
   EnhancedBass.isSupported(by: deviceInfo.model) {

    nothingEarDevice.setEnhancedBass(EnhancedBassSettings(isEnabled: true, level: 50))
    nothingEarDevice.setEnhancedBass(EnhancedBassSettings(isEnabled: false, level: 0))
}
```

## Other Settings

```swift
nothingEarDevice.setInEarDetection(true)
nothingEarDevice.setLowLatency(true)
```

## Reading Current State

```swift
if let deviceInfo = nothingEarDevice.deviceInfo {
    let model = deviceInfo.model
    print("Device: \(model.displayName)")
    print("ANC support: \(NoiseCancellationMode.isSupported(by: model))")
}

if let battery = nothingEarDevice.battery {
    print("Battery: \(battery)")
}

if let ancMode = nothingEarDevice.ancMode {
    print("ANC mode: \(ancMode.displayName)")
}

if let eqPreset = nothingEarDevice.eqPreset {
    print("EQ preset: \(eqPreset.displayName)")
}

if let settings = nothingEarDevice.deviceSettings {
    print("In-ear detection: \(settings.inEarDetection)")
    print("Low latency: \(settings.lowLatency)")
}
```

## Error Handling

```swift
onError: { error in
    switch error {
    case .bluetooth(let bluetoothError):
        switch bluetoothError {
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unauthorized:
            print("Bluetooth access not authorized")
        case .unavailable:
            print("Bluetooth is unavailable")
        }
    case .deviceNotFound:
        print("Device not found")
    case .connectionFailed:
        print("Failed to connect")
    case .unsupportedOperation:
        print("Operation not supported by this model")
    case .timeout:
        print("Operation timed out")
    case .invalidResponse:
        print("Invalid response from device")
    }
}
```
