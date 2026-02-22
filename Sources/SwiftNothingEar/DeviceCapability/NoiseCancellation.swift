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

extension NoiseCancellationMode: DeviceCapability {

    public static func isSupported(by model: DeviceModel) -> Bool {
        switch model {
            case .ear1,
                 .ear2,
                 .ear3,
                 .ear,
                 .earA,
                 .headphone1,
                 .cmfBuds,
                 .cmfBudsPro,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBudsPro2,
                 .cmfNeckbandPro,
                 .cmfHeadphonePro:
                true

            case .earStick,
                 .earOpen:
                false
        }
    }
}
