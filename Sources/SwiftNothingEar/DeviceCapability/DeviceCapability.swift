import Foundation

protocol DeviceCapability {
        
    func isSupported(by model: Model) -> Bool
}
