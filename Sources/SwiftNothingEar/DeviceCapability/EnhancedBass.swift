import Foundation

public struct EnhancedBass: Sendable {

    public let isEnabled: Bool
    public let level: Int // 1-5

    public init(isEnabled: Bool, level: Int) {
        self.isEnabled = isEnabled
        self.level = level
    }
}

extension EnhancedBass: DeviceCapability {

    public static func isSupported(by model: DeviceModel) -> Bool {
        switch model {
            case .ear3,
                 .ear,
                 .earA,
                 .headphone1,
                 .headphoneA,
                 .cmfBuds,
                 .cmfBudsNeo,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBuds2Plus,
                 .cmfBudsPro2,
                 .cmfNeckbandPro,
                 .cmfHeadphonePro,
                 .cmfClipPro:
                true
            case .ear1,
                 .ear2,
                 .ear3A,
                 .earStick,
                 .earOpen,
                 .cmfBudsPro:
                false
        }
    }
}
