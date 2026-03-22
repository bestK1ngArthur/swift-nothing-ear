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
- 🟢 [Nothing Ear (a)](Docs/ear_a.md)
- 🟢 [Nothing Headphone (1)](Docs/headphones_1.md)
- 🟡 [Nothing Headphone (a)](Docs/headphones_a.md)
- 🟡 [CMF Buds](Docs/cmf_buds.md)
- 🟡 [CMF Buds 2a](Docs/cmf_buds_2a.md)
- 🟢 [CMF Buds 2](Docs/cmf_buds_2.md)
- 🟡 [CMF Buds 2 Plus](Docs/cmf_buds_2_plus.md)
- 🟡 [CMF Buds Pro](Docs/cmf_buds_pro.md)
- 🟢 [CMF Buds Pro 2](Docs/cmf_buds_pro_2.md)
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

See [QUICKSTART.md](QUICKSTART.md) for setup, connection management, ANC/EQ/gesture control, and error handling examples.

## How to Contribute

1. Fork the repository.
2. Implement a new feature, fix a bug, or make any changes you'd like. You can use AI agents or any tools you prefer to help with coding, but please review and test your code manually before submitting.
3. Create a pull request describing what you've done and why it should be merged into the app. I'll review the changes, which may take some time. I may also ask you to make some modifications. In rare cases, I might decline the pull request with an explanation.
4. After merging, once enough changes have accumulated for a release, I'll build an update and make it available to all users.
5. Thank you for your contribution — you're awesome!

If you can't code but have ideas on how to improve the app, please [create an issue](https://github.com/bestK1ngArthur/swift-nothing-ear/issues/new/choose) and describe your idea, bug report, or any other needed change. I'll do my best to implement the necessary functionality in my spare time.

## Legal Disclaimer

1. This software is not affiliated with, sponsored by, or endorsed by Nothing Technology. This software is a third-party project and is NOT an official Nothing product.

2. Nothing, the Nothing logo and other brand related content are trademarks of Nothing Technology Limited and are protected by copyright, trademark, and other intellectual property laws.

3. You use this software at your own risk. The developer makes no warranties regarding compatibility with all firmware versions, performance, or reliability. 

4. The developer shall not be liable for any direct or indirect damages arising from the use of the software, including data loss, hardware damage, or degraded audio quality. 

5. By installing and using this software, you agree to the terms of this disclaimer.

If you have questions, [contact me](mailto:bestk1ngarthur@aol.com).
