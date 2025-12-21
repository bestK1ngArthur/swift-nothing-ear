import Foundation

protocol DeviceCapability {
        
    func isSupported(by model: DeviceModel) -> Bool
}
