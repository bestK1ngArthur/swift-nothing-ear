import Foundation

/// Sound modes available on CMF speakers.
public enum SpeakerSoundMode: Equatable, Sendable {
    case normal
    /// Auto-off duration encoded in minutes.
    case night(autoOffMinutes: UInt16)
}

extension SpeakerSoundMode: DeviceCapability {
    public static func isSupported(by model: DeviceModel) -> Bool {
        model.isSpeaker
    }
}
