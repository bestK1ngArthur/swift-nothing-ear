import Foundation

public struct DeviceSettings: Sendable {

    public var inEarDetection: Bool
    public var lowLatency: Bool
    public var personalizedANC: Bool

    public static let `default` = Self(
        inEarDetection: false,
        lowLatency: false,
        personalizedANC: false
    )
}
