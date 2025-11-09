import Foundation

extension NothingEar {

    public struct DeviceInfo: Sendable {
        public var model: Model
        public var serialNumber: String
        public var bluetoothAddress: String?
        public var firmwareVersion: String?

        public static let empty = Self(
            model: .ear(.black),
            serialNumber: "",
            bluetoothAddress: nil,
            firmwareVersion: nil
        )
    }

    public struct DeviceSettings: Sendable {
        public var inEarDetection: Bool
        public var lowLatency: Bool
        public var personalizedANC: Bool

        public static let `default` = Self(inEarDetection: false, lowLatency: false, personalizedANC: false)
    }

    public struct BatteryLevel: Sendable {
        public let level: Int // 0-100
        public let isCharging: Bool
        public let isConnected: Bool

        public static let disconnected = Self(level: 0, isCharging: false, isConnected: false)
    }

    public enum Battery: Sendable {
        case budsWithCase(case: BatteryLevel, leftBud: BatteryLevel, rightBud: BatteryLevel)
        case single(BatteryLevel)
    }

    public enum ANCMode: CaseIterable, Hashable, Sendable {
        public enum NoiseCancellation: CaseIterable, Sendable {
            case low
            case mid
            case high
            case adaptive
        }

        case off
        case transparent
        case noiseCancellation(NoiseCancellation)

        public static var allCases: [NothingEar.ANCMode] {
            [.noiseCancellation(.adaptive), .transparent, .off]
        }
    }

    public enum SpatialAudioMode: CaseIterable, Hashable, Sendable {
        case off
        case fixed
        case headTracking
    }

    public enum EQPreset: CaseIterable, Sendable {
        case balanced
        case voice
        case moreTreble
        case moreBass
        case custom
        case advanced
    }

    public struct EQPresetCustom: Sendable {
        public let lowFrequency: Float  // Usually ~100Hz
        public let midFrequency: Float  // Usually ~1kHz
        public let highFrequency: Float // Usually ~10kHz
    }

    public struct EnhancedBassSettings: Sendable {
        public let isEnabled: Bool
        public let level: Int // 0-100

        public init(isEnabled: Bool, level: Int) {
            self.isEnabled = isEnabled
            self.level = level
        }
    }

    public enum GestureDevice: Sendable {
        case left
        case right
    }

    public enum GestureType: Sendable {
        case tap
        case doubleTap
        case trippleTap
        case longPress
    }

    public enum GestureAction: Sendable {
        case none
        case playPause
        case nextTrack
        case previousTrack
        case volumeUp
        case volumeDown
        case voiceAssistant
        case ancToggle
        case customAction
    }

    public struct RingBuds: Sendable {

        public enum Bud: Sendable {
            case left
            case right
            case unibody
        }

        public let isOn: Bool
        public let bud: Bud

        public init(isOn: Bool, bud: Bud) {
            self.isOn = isOn
            self.bud = bud
        }
    }
}

// MARK: Active Noise Cancellation Mode

extension NothingEar.ANCMode {

    public var displayName: String {
        switch self {
            case .off: return "Off"
            case .transparent: return "Transparency"
            case .noiseCancellation: return "Noise Cancellation"
        }
    }
}

extension NothingEar.ANCMode.NoiseCancellation {

    public var displayName: String {
        switch self {
            case .low: return "Low"
            case .mid: return "Mid"
            case .high: return "High"
            case .adaptive: return "Adaptive"
        }
    }
}

// MARK: Spatial Audio Mode

extension NothingEar.SpatialAudioMode {

    public var displayName: String {
        switch self {
            case .off: return "Off"
            case .fixed: return "Fixed"
            case .headTracking: return "Head-tracking"
        }
    }
}

// MARK: Equalizer Preset

extension NothingEar.EQPreset {

    public var displayName: String {
        switch self {
            case .balanced: return "Balanced"
            case .voice: return "Voice"
            case .moreTreble: return "More Treble"
            case .moreBass: return "More Bass"
            case .custom: return "Custom"
            case .advanced: return "Advanced"
        }
    }
}
