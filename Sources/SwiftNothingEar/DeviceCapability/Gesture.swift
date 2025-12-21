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
    case customAction
}
