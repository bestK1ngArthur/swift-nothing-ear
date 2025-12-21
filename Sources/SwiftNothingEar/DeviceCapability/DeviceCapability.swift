import Foundation

public protocol DeviceCapability {

    static func isSupported(by model: DeviceModel) -> Bool
}
