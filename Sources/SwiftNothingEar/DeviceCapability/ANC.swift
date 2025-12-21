import Foundation

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

    public static var allCases: [ANCMode] {
        [.noiseCancellation(.adaptive), .transparent, .off]
    }
}

extension ANCMode {

    public var displayName: String {
        switch self {
            case .off: return "Off"
            case .transparent: return "Transparency"
            case .noiseCancellation: return "Noise Cancellation"
        }
    }
}

extension ANCMode.NoiseCancellation {

    public var displayName: String {
        switch self {
            case .low: return "Low"
            case .mid: return "Mid"
            case .high: return "High"
            case .adaptive: return "Adaptive"
        }
    }
}

extension ANCMode: DeviceCapability {

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
