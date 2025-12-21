import Foundation

public enum SpatialAudioMode: CaseIterable, Hashable, Sendable {
    case off
    case fixed
    case headTracking
}

extension SpatialAudioMode {

    public var displayName: String {
        switch self {
            case .off: "Off"
            case .fixed: "Fixed"
            case .headTracking: "Head-tracking"
        }
    }
}

extension SpatialAudioMode: DeviceCapability {

    public static func isSupported(by model: DeviceModel) -> Bool {
        switch model {
            case .ear1,
                 .ear2,
                 .ear3,
                 .headphone1,
                 .cmfBudsPro,
                 .cmfBuds2,
                 .cmfBudsPro2,
                 .cmfNeckbandPro,
                 .cmfHeadphonePro:
                true

            case .earStick,
                .earOpen,
                .ear,
                .earA,
                .cmfBuds:
                false
        }
    }

    public static func allSupported(by model: DeviceModel) -> [Self] {
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

    public static func isCompatibleWithEnhancedBass(by model: DeviceModel) -> Bool {
        switch model {
            case .cmfBudsPro,
                 .cmfBuds,
                 .cmfBuds2,
                 .cmfBudsPro2,
                 .cmfNeckbandPro,
                 .cmfHeadphonePro:
                true

            case .ear1,
                 .ear2,
                 .ear3,
                 .earStick,
                 .earOpen,
                 .ear,
                 .earA,
                 .headphone1:
                false
        }
    }
}
