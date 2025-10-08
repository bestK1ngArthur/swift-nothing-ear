import Foundation

extension NothingEar {

    /// Supported Nothing Ear device models
    public enum Model: Sendable {
        case ear1(Ear1)                       // Nothing Ear (1)
        case ear2(Ear2)                       // Nothing Ear (2)
        case ear3(Ear3)                       // Nothing Ear (3)
        case earStick                         // Nothing Ear (stick)
        case earOpen                          // Nothing Ear (open)
        case ear(Ear)                         // Nothing Ear
        case earA(EarA)                       // Nothing Ear (a)
        case headphone1(Headphone1)           // Nothing Headphone (1)
        case cmfBudsPro(CMFBudsPro)           // CMF Buds Pro
        case cmfBuds(CMFBuds)                 // CMF Buds
        case cmfBudsPro2(CMFBudsPro2)         // CMF Buds Pro 2
        case cmfNeckbandPro(CMFNeckbandPro)   // CMF Neckband Pro
        case cmfHeadphonePro(CMFHeadphonePro) // CMF Headphone Pro
    }
}

extension NothingEar.Model {

    public enum Ear1: Sendable {
        case black
        case white
    }

    public enum Ear2: Sendable {
        case black
        case white
    }

    public enum Ear3: Sendable {
        case black
        case white
    }

    public enum Ear: Sendable {
        case black
        case white
    }

    public enum EarA: Sendable {
        case black
        case white
        case yellow
    }

    public enum Headphone1: Sendable {
        case black
        case grey
    }

    public enum CMFBudsPro: Sendable {
        case orange
        case white
        case black
    }

    public enum CMFBuds: Sendable {
        case black
        case orange
        case white
    }

    public enum CMFBudsPro2: Sendable {
        case black
        case blue
        case orange
        case white
    }

    public enum CMFNeckbandPro: Sendable {
        case black
        case orange
        case white
    }

    public enum CMFHeadphonePro: Sendable {
        case lightGreen
        case lightGrey
        case darkGrey
    }

    public var displayName: String {
        switch self {
            case .ear1: return "Nothing Ear (1)"
            case .ear2: return "Nothing Ear (2)"
            case .ear3: return "Nothing Ear (3)"
            case .earStick: return "Nothing Ear (stick)"
            case .earOpen: return "Nothing Ear (open)"
            case .ear: return "Nothing Ear"
            case .earA: return "Nothing Ear (a)"
            case .headphone1: return "Nothing Headphone (1)"
            case .cmfBudsPro: return "CMF Buds Pro"
            case .cmfBuds: return "CMF Buds"
            case .cmfBudsPro2: return "CMF Buds Pro 2"
            case .cmfNeckbandPro: return "CMF Neckband Pro"
            case .cmfHeadphonePro: return "CMF Headphone Pro"
        }
    }

    public var code: String {
        switch self {
            case .ear1: "B181"
            case .ear2: "B155"
            case .ear3: "B156"
            case .earStick: "B157"
            case .earOpen: "B182"
            case .ear: "B171"
            case .earA: "B162"
            case .headphone1: "B170"
            case .cmfBudsPro: "B163"
            case .cmfBuds: "B168"
            case .cmfBudsPro2: "B172"
            case .cmfNeckbandPro: "B164"
            case .cmfHeadphonePro: "B175"
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

    public var supportsSpatialAudio: Bool {
        switch self {
            case .ear1, .earStick:
                return false
            default:
                return true
        }
    }

    public var supportsCustomEQ: Bool {
        if case .earStick = self {
            return false
        }

        return true
    }

    public var supportsEnhancedBass: Bool {
        switch self {
            case .ear, .cmfBudsPro2, .cmfBuds, .earA, .headphone1, .cmfHeadphonePro:
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
            return .ear1(.white)
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
                // M3 prefixed serials: extract SKU from positions 3-6
                guard serialNumber.count >= 6 else { return nil }
                let skuStart = serialNumber.index(serialNumber.startIndex, offsetBy: 3)
                let skuEnd = serialNumber.index(skuStart, offsetBy: 3)
                sku = String(serialNumber[skuStart..<skuEnd])

            default:
                sku = ""
        }

        return getModel(fromSKU: sku)
    }

    private static func getModel(fromSKU sku: String) -> Self? {
        return switch sku {
            case "01", "03", "07":
                .ear1(.white)
            case "02", "04", "06", "08", "10":
                .ear1(.black)
            case "14", "15", "16":
                .earStick
            case "11200005":
                .earOpen
            case "17", "18", "19":
                .ear2(.white)
            case "27", "28", "29":
                .ear2(.black)
            case "25":
                .ear3(.white)
            case "26":
                .ear3(.black)
            case "30", "31":
                .cmfBudsPro(.black)
            case "32", "33":
                .cmfBudsPro(.white)
            case "34", "35":
                .cmfBudsPro(.orange)
            case "48", "53":
                .cmfNeckbandPro(.orange)
            case "49", "52":
                .cmfNeckbandPro(.white)
            case "50", "51":
                .cmfNeckbandPro(.black)
            case "54", "55":
                .cmfBuds(.black)
            case "56", "57":
                .cmfBuds(.white)
            case "58", "59":
                .cmfBuds(.orange)
            case "61", "69", "74":
                .ear(.black)
            case "62", "70", "75":
                .ear(.white)
            case "63", "66", "71":
                .earA(.black)
            case "64", "67", "72":
                .earA(.white)
            case "65", "68", "73":
                .earA(.yellow)
            case "76", "83":
                .cmfBudsPro2(.black)
            case "77", "82":
                .cmfBudsPro2(.white)
            case "78", "81":
                .cmfBudsPro2(.orange)
            case "79", "80":
                .cmfBudsPro2(.blue)
            case "603":
                .headphone1(.black)
            case "606":
                .headphone1(.grey)
            case "84", "87":
                .cmfHeadphonePro(.darkGrey)
            case "85", "88":
                .cmfHeadphonePro(.lightGrey)
            case "86", "89":
                .cmfHeadphonePro(.lightGreen)
            default:
                nil
        }
    }
}
