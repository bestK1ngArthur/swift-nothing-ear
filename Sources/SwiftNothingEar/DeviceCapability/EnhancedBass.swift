import Foundation

public struct EnhancedBassSettings: Sendable {

    public let isEnabled: Bool
    public let level: Int // 0-100

    public init(isEnabled: Bool, level: Int) {
        self.isEnabled = isEnabled
        self.level = level
    }
}
