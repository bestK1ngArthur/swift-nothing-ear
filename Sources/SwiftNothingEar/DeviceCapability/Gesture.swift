import Foundation

public enum GestureDevice: Sendable {
    case left
    case right
}

public enum GestureType: Sendable {
    case tap
    case doubleTap
    case trippleTap
    case longPress
}

public enum GestureAction: Sendable {
    case none
    case playPause
    case nextTrack
    case previousTrack
    case volumeUp
    case volumeDown
    case voiceAssistant
    case ancToggle
    /// A device-specific action this package does not model (e.g. Nothing Radio, camera shutter).
    /// Only produced when reading gestures; it cannot be written.
    case customAction
}
