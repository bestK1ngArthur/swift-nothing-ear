import Foundation

public enum SpatialAudioMode: Hashable, Sendable {
    case off
    case fixed
    case headTracking
    case cinema
    case concert
}

extension SpatialAudioMode {

    public var displayName: String {
        switch self {
            case .off: "Off"
            case .fixed: "Fixed"
            case .headTracking: "Head-tracking"
            case .cinema: "Cinema"
            case .concert: "Concert"
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
                 .cmfBuds2Plus,
                 .cmfBudsPro2,
                 .cmfNeckbandPro,
                 .cmfHeadphonePro:
                true

            case .earStick,
                .earOpen,
                .ear,
                .earA,
                .cmfBuds2a,
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
                 .cmfBuds2,
                 .cmfBuds2Plus,
                 .cmfBudsPro2,
                 .cmfNeckbandPro:
                [.off, .fixed]

            case .cmfHeadphonePro:
                [.off, .cinema, .concert]

            case .earStick,
                .earOpen,
                .ear,
                .earA,
                .cmfBuds2a,
                .cmfBuds,
                .cmfBudsPro:
                []
        }
    }

    public static func isCompatibleWithEnhancedBass(by model: DeviceModel) -> Bool {
        switch model {
            case .cmfBudsPro,
                 .cmfBuds,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBuds2Plus,
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
