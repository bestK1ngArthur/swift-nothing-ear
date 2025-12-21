import Foundation

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

extension EQPreset {

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

extension EQPreset: DeviceCapability {

    public static func isSupported(by model: DeviceModel) -> Bool {
        true
    }

    public static func allSupported(by model: DeviceModel) -> [Self] {
        switch model {
            case .ear1,
                 .ear2,
                 .ear3,
                 .earStick,
                 .earOpen,
                 .ear,
                 .earA,
                 .headphone1,
                 .cmfBuds,
                 .cmfBuds2,
                 .cmfBudsPro,
                 .cmfBudsPro2, // TODO: Add genre presets
                 .cmfHeadphonePro:
                [.balanced, .voice, .moreTreble, .moreBass, .custom, .advanced]

            case .cmfNeckbandPro:
                [.balanced, .voice, .moreTreble, .moreBass, .custom]
        }
    }
}

// MARK: Listening Mode

extension DeviceModel {

    var isListeningModeSupported: Bool {
        switch self {
            case .cmfBuds, .cmfBuds2, .cmfBudsPro2:
                return true
            default:
                return false
        }
    }
}
