import Foundation

public enum GestureDevice: Sendable, Hashable, CaseIterable {
    case left
    case right
}

public enum GestureType: Sendable, Hashable, CaseIterable {
    case tap
    case doubleTap
    case trippleTap
    case longPress
}

public enum GestureAction: Sendable, Hashable, CaseIterable {
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

public struct DeviceGesture: Hashable, Sendable, Identifiable {
    public let device: GestureDevice
    public let type: GestureType
    public let action: GestureAction

    public var id: String {
        "\(device)-\(type)-\(action)"
    }

    public init(device: GestureDevice, type: GestureType, action: GestureAction) {
        self.device = device
        self.type = type
        self.action = action
    }
}

extension DeviceGesture: DeviceCapability {

    public static func isSupported(by model: DeviceModel) -> Bool {
        switch model {
            case .ear1,
                 .ear2,
                 .ear3,
                 .ear3A,
                 .ear,
                 .earA,
                 .earStick,
                 .earOpen,
                 .headphone1,
                 .cmfBuds,
                 .cmfBudsPro,
                 .cmfBuds2a,
                 .cmfBuds2,
                 .cmfBuds2Plus,
                 .cmfBudsPro2,
                 .cmfNeckbandPro:
                true

            case .headphoneA,
                 .cmfHeadphonePro:
                false
        }
    }
}

extension GestureDevice {

    public var displayName: String {
        switch self {
            case .left: "Left"
            case .right: "Right"
        }
    }
}

extension GestureType {

    public var displayName: String {
        switch self {
            case .tap: "Tap"
            case .doubleTap: "Double Tap"
            case .trippleTap: "Triple Tap"
            case .longPress: "Long Press"
        }
    }
}

extension GestureAction {

    public var displayName: String {
        switch self {
            case .none: "None"
            case .playPause: "Play / Pause"
            case .nextTrack: "Next Track"
            case .previousTrack: "Previous Track"
            case .volumeUp: "Volume Up"
            case .volumeDown: "Volume Down"
            case .voiceAssistant: "Voice Assistant"
            case .ancToggle: "ANC Toggle"
            case .customAction: "Custom Action"
        }
    }
}
