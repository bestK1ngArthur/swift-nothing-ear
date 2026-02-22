import Foundation

public struct EnhancedBass: Sendable {

    public let isEnabled: Bool
    public let level: Int // 0-100

    public init(isEnabled: Bool, level: Int) {
        self.isEnabled = isEnabled
        self.level = level
    }
}

extension EnhancedBass: DeviceCapability {

    public static func isSupported(by model: DeviceModel) -> Bool {
        switch model {
            case .ear1,
                 .ear2,
                 .ear3,
                 .ear,
                 .earA,
                 .earStick,
                 .headphone1,
                 .cmfBuds,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBuds2Plus,
                 .cmfBudsPro,
                 .cmfBudsPro2,
                 .cmfNeckbandPro,
                 .cmfHeadphonePro:
                true
            case .earOpen:
                false
        }
    }
}
