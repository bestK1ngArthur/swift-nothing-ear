import Foundation

public struct DeviceInfo: Sendable {

    public var model: Model
    public var serialNumber: String
    public var bluetoothAddress: String?
    public var firmwareVersion: String?

    public static let empty = Self(
        model: .ear(.black),
        serialNumber: "",
        bluetoothAddress: nil,
        firmwareVersion: nil
    )
}
