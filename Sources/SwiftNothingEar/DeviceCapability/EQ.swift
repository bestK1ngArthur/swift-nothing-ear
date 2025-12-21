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

// MARK: Listening Mode

extension Model {

    var isListeningModeSupported: Bool {
        switch self {
            case .cmfBuds, .cmfBuds2, .cmfBudsPro2:
                return true
            default:
                return false
        }
    }
}
