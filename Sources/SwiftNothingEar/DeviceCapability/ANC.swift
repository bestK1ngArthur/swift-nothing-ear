import Foundation

public enum ANCMode: CaseIterable, Hashable, Sendable {

    public enum NoiseCancellation: CaseIterable, Sendable {
        case low
        case mid
        case high
        case adaptive
    }

    case off
    case transparent
    case noiseCancellation(NoiseCancellation)

    public static var allCases: [ANCMode] {
        [.noiseCancellation(.adaptive), .transparent, .off]
    }
}

extension ANCMode {

    public var displayName: String {
        switch self {
            case .off: return "Off"
            case .transparent: return "Transparency"
            case .noiseCancellation: return "Noise Cancellation"
        }
    }
}

extension ANCMode.NoiseCancellation {

    public var displayName: String {
        switch self {
            case .low: return "Low"
            case .mid: return "Mid"
            case .high: return "High"
            case .adaptive: return "Adaptive"
        }
    }
}
