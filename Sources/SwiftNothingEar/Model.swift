import Foundation

extension NothingEar {

    /// Supported Nothing Ear device models
    public enum Model: String, CaseIterable, Sendable {
        case ear1 = "B181"           // Nothing Ear (1)
        case ear2 = "B155"           // Nothing Ear (2)
        case earStick = "B157"       // Nothing Ear (stick)
        case earOpen = "B174"        // Nothing Ear (open)
        case ear = "B171"            // Nothing Ear
        case earA = "B162"           // Nothing Ear (a)
        case headphone1 = "B175"     // Nothing Headphone (1)
        case cmfBudsPro = "B163"     // CMF Buds Pro
        case cmfBuds = "B168"        // CMF Buds
        case cmfBudsPro2 = "B172"    // CMF Buds Pro 2
        case cmfNeckbandPro = "B164" // CMF Neckband Pro
    }
}

extension NothingEar.Model {

    public var displayName: String {
        switch self {
            case .ear1: return "Nothing Ear (1)"
            case .ear2: return "Nothing Ear (2)"
            case .earStick: return "Nothing Ear (stick)"
            case .earOpen: return "Nothing Ear (open)"
            case .ear: return "Nothing Ear"
            case .earA: return "Nothing Ear (a)"
            case .headphone1: return "Nothing Headphone (1)"
            case .cmfBudsPro: return "CMF Buds Pro"
            case .cmfBuds: return "CMF Buds"
            case .cmfBudsPro2: return "CMF Buds Pro 2"
            case .cmfNeckbandPro: return "CMF Neckband Pro"
        }
    }

    public var supportsANC: Bool {
        switch self {
            case .earStick, .earOpen:
                return false
            default:
                return true
        }
    }

    public var supportsCustomEQ: Bool {
        return self != .earStick
    }

    public var supportsEnhancedBass: Bool {
        switch self {
            case .ear, .cmfBudsPro2, .cmfBuds, .earA, .headphone1:
                return true
            default:
                return false
        }
    }

    public var supportsInEarDetection: Bool {
        switch self {
            case .earOpen:
                return false
            default:
                return true
        }
    }
}

// MARK: Model Detection

extension NothingEar.Model {

    static func getModel(fromSerialNumber serialNumber: String) -> Self? {
        // Handle special test serial number for Ear (1)
        if serialNumber == "12345678901234567" {
            return .ear1
        }

        guard serialNumber.count >= 8 else {
            return nil
        }

        let sku: String
        let headSerial = String(serialNumber.prefix(2))
        switch headSerial {
            case "MA":
                // MA prefixed serials: check year to determine model
                let yearStart = serialNumber.index(serialNumber.startIndex, offsetBy: 6)
                let yearEnd = serialNumber.index(yearStart, offsetBy: 2)
                let year = String(serialNumber[yearStart..<yearEnd])

                if year == "22" || year == "23" {
                    // Ear (stick)
                    sku = "14"
                } else if year == "24" {
                    // Ear (open) - this is a guess based on the year
                    sku = "11200005"
                } else {
                    sku = ""
                }

            case "SH", "13":
                // SH and 13 prefixed serials: extract SKU from positions 4-6
                guard serialNumber.count >= 6 else { return nil }
                let skuStart = serialNumber.index(serialNumber.startIndex, offsetBy: 4)
                let skuEnd = serialNumber.index(skuStart, offsetBy: 2)
                sku = String(serialNumber[skuStart..<skuEnd])

            case "M3":
                sku = "08"

            default:
                sku = ""
        }

        return getModel(fromSKU: sku)
    }

    private static func getModel(fromSKU sku: String) -> Self? {
        return switch sku {
            case "01": .ear1
            case "14": .earStick
            case "11200005": .earOpen
            case "02": .ear2
            case "03": .ear
            case "04": .earA
            case "05": .cmfBudsPro
            case "06": .cmfBuds
            case "07": .cmfBudsPro2
            case "08": .headphone1
            default: nil
        }
    }
}
