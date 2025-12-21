import Foundation

public enum SpatialAudioMode: CaseIterable, Hashable, Sendable {
    case off
    case fixed
    case headTracking
}

extension SpatialAudioMode {

    public var displayName: String {
        switch self {
            case .off: return "Off"
            case .fixed: return "Fixed"
            case .headTracking: return "Head-tracking"
        }
    }

    public static func allSupported(by model: Model) -> [Self] {
        switch model {
            case .headphone1:
                [.off, .fixed, .headTracking]

            case .ear1,
                 .ear2,
                 .ear3,
                 .cmfBudsPro,
                 .cmfBuds2,
                 .cmfBudsPro2,
                 .cmfNeckbandPro,
                 .cmfHeadphonePro: // TODO: Add concert/cinema mode
                [.off, .fixed]

            case .earStick,
                .earOpen,
                .ear,
                .earA,
                .cmfBuds:
                []
        }
    }
}
