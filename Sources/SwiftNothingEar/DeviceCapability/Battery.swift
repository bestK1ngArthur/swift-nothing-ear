import Foundation

public struct BatteryLevel: Sendable {

    public let level: Int // 0-100
    public let isCharging: Bool
    public let isConnected: Bool

    public static let disconnected = Self(level: 0, isCharging: false, isConnected: false)
}

public enum Battery: Sendable {
    case budsWithCase(case: BatteryLevel, leftBud: BatteryLevel, rightBud: BatteryLevel)
    case single(BatteryLevel)
}
