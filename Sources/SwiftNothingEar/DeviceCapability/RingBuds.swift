import Foundation

public struct RingBuds: Sendable {

    public enum Bud: Sendable {
        case left
        case right
        case unibody
    }

    public let isOn: Bool
    public let bud: Bud

    public init(isOn: Bool, bud: Bud) {
        self.isOn = isOn
        self.bud = bud
    }
}
