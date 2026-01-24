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

    public let bass: Int   // Range: -6...6
    public let mid: Int    // Range: -6...6
    public let treble: Int // Range: -6...6

    public init(bass: Int, mid: Int, treble: Int) {
        self.bass = bass
        self.mid = mid
        self.treble = treble
    }
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
