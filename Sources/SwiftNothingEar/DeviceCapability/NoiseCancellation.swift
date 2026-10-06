import Foundation

public enum NoiseCancellationMode: CaseIterable, Hashable, Sendable {

    public enum Active: CaseIterable, Sendable {
        case low
        case mid
        case high
        case adaptive
    }

    case off
    case transparent
    case active(Active)

    public static var allCases: [NoiseCancellationMode] {
        [.active(.adaptive), .transparent, .off]
    }
}

extension NoiseCancellationMode {

    public var displayName: String {
        switch self {
            case .off: return "Off"
            case .transparent: return "Transparency"
            case .active: return "Active"
        }
    }
}

extension NoiseCancellationMode.Active {

    public var displayName: String {
        switch self {
            case .low: return "Low"
            case .mid: return "Mid"
            case .high: return "High"
            case .adaptive: return "Adaptive"
        }
    }
}

extension NoiseCancellationMode.Active {

    /// Active levels the model offers.
    public static func allSupported(by model: DeviceModel) -> [Self] {
        guard NoiseCancellationMode.isSupported(by: model) else {
            return []
        }

        switch model {
            case .ear1:
                return [.low, .high]

            case .cmfBudsPro,
                 .cmfBuds,
                 .cmfBuds2a:
                // No adaptive level. CMF Buds and Buds 2a may have a single level,
                // which is unconfirmed, so all three are kept.
                return [.low, .mid, .high]

            default:
                return allCases
        }
    }
}

extension NoiseCancellationMode {

    /// Modes the model offers. Active uses adaptive when available, otherwise the highest level.
    public static func allSupported(by model: DeviceModel) -> [Self] {
        let levels = Active.allSupported(by: model)
        guard let level = levels.contains(.adaptive) ? .adaptive : levels.last else {
            return []
        }

        return [.active(level), .transparent, .off]
    }
}

extension NoiseCancellationMode: DeviceCapability {

    public static func isSupported(by model: DeviceModel) -> Bool {
        switch model {
            case .ear1,
                 .ear2,
                 .ear3,
                 .ear3A,
                 .ear,
                 .earA,
                 .headphone1,
                 .headphone1Pro,
                 .headphoneA,
                 .cmfBuds,
                 .cmfBudsNeo,
                 .cmfBudsPro,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBuds2Plus,
                 .cmfBudsPro2,
                 .cmfNeckbandPro,
                 .cmfHeadphonePro:
                true

            case .earStick,
                 .earOpen,
                 .cmfClipPro:
                false
        }
    }
}
