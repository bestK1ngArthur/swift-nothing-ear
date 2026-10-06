import Foundation

public enum EQPreset: CaseIterable, Sendable {
    // Nothing presets
    case balanced
    case voice
    case moreTreble
    case moreBass
    case newVoice
    case newInstrument

    // Genre presets of CMF models
    case immersionBoost
    case pop
    case rock
    case electronic
    case enhanceVocals
    case classical

    case custom
    /// Advanced EQ is a separate mode on the device rather than a preset value:
    /// it is reported while the mode is on, and selecting another preset turns it off.
    case advanced
}

extension EQPreset {

    public var displayName: String {
        switch self {
            case .balanced: return "Balanced"
            case .voice: return "Voice"
            case .moreTreble: return "More Treble"
            case .moreBass: return "More Bass"
            case .newVoice: return "New Voice"
            case .newInstrument: return "New Instrument"
            case .immersionBoost: return "Immersion Boost"
            case .pop: return "Pop"
            case .rock: return "Rock"
            case .electronic: return "Electronic"
            case .enhanceVocals: return "Enhance Vocals"
            case .classical: return "Classical"
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
            case .ear2,
                 .ear3,
                 .ear3A,
                 .earStick,
                 .earOpen,
                 .ear,
                 .headphone1,
                 .headphoneA:
                [.balanced, .voice, .moreTreble, .moreBass, .custom, .advanced]

            case .headphone1Pro:
                [.balanced, .voice, .moreTreble, .moreBass, .newInstrument, .custom, .advanced]

            // Models with genre presets
            case .cmfBuds,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBudsPro2:
                [.balanced, .pop, .rock, .electronic, .enhanceVocals, .classical, .custom]

            case .cmfBudsNeo:
                [.immersionBoost, .pop, .rock, .electronic, .enhanceVocals, .classical, .custom]

            case .cmfBuds2Plus,
                 .cmfHeadphonePro,
                 .cmfClipPro:
                [.pop, .rock, .electronic, .enhanceVocals, .classical, .custom]

            case .earA,
                 .cmfBudsPro,
                 .cmfNeckbandPro:
                [.balanced, .voice, .moreTreble, .moreBass, .custom]

            case .ear1:
                [.balanced, .voice, .moreTreble, .moreBass]
        }
    }
}

// MARK: Listening Mode

extension DeviceModel {

    /// Whether presets are listening modes (0xC050/0xF01D) instead of EQ modes.
    var supportsListeningMode: Bool {
        switch self {
            case .cmfBuds,
                 .cmfBudsNeo,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBuds2Plus,
                 .cmfBudsPro2,
                 .cmfHeadphonePro,
                 .cmfClipPro:
                return true
            default:
                return false
        }
    }
}

// MARK: Custom EQ

public struct EQPresetCustom: Equatable, Sendable {

    public let bass: Int   // Range: -6...6
    public let mid: Int    // Range: -6...6
    public let treble: Int // Range: -6...6

    public init(bass: Int, mid: Int, treble: Int) {
        self.bass = bass
        self.mid = mid
        self.treble = treble
    }
}

struct EQPresetCustomSpecs: Sendable {

    let freqLow: Float
    let qLow: Float
    let freqPeak: Float
    let qPeak: Float
    let freqHigh: Float
    let qHigh: Float
}

extension DeviceModel {

    var eqPresetCustomSpecs: EQPresetCustomSpecs {
        let spec3400 = EQPresetCustomSpecs(
            freqLow: 140.0,
            qLow: 0.8,
            freqPeak: 980.0,
            qPeak: 0.7,
            freqHigh: 3400.0,
            qHigh: 1.0
        )
        let spec3500 = EQPresetCustomSpecs(
            freqLow: 140.0,
            qLow: 0.8,
            freqPeak: 980.0,
            qPeak: 0.7,
            freqHigh: 3500.0,
            qHigh: 1.0
        )
        let spec3500AltPeak = EQPresetCustomSpecs(
            freqLow: 140.0,
            qLow: 0.8,
            freqPeak: 980.0,
            qPeak: 0.66,
            freqHigh: 3500.0,
            qHigh: 1.0
        )
        let spec6900 = EQPresetCustomSpecs(
            freqLow: 140.0,
            qLow: 0.8,
            freqPeak: 980.0,
            qPeak: 0.7,
            freqHigh: 6900.0,
            qHigh: 1.0
        )

        switch self {
            case .headphone1,
                 .headphone1Pro,
                 .headphoneA,
                 .cmfHeadphonePro:
                return spec3500

            case .earStick:
                return spec3500AltPeak

            case .ear1,
                 .ear2,
                 .ear3,
                 .ear3A,
                 .earOpen,
                 .ear,
                 .earA,
                 .cmfBudsPro,
                 .cmfBudsNeo,
                 .cmfClipPro:
                return spec3400

            case .cmfBuds,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBuds2Plus,
                 .cmfBudsPro2,
                 .cmfNeckbandPro:
                return spec6900
        }
    }
}
