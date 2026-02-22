import Foundation

/// Supported Nothing Ear device models
public enum DeviceModel: Sendable, Equatable {
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
    case cmfBuds2a(CMFBuds2a)             // CMF Buds 2a
    case cmfBuds2(CMFBuds2)               // CMF Buds 2
    case cmfBuds2Plus(CMFBuds2Plus)       // CMF Buds 2 Plus
    case cmfBudsPro2(CMFBudsPro2)         // CMF Buds Pro 2
    case cmfNeckbandPro(CMFNeckbandPro)   // CMF Neckband Pro
    case cmfHeadphonePro(CMFHeadphonePro) // CMF Headphone Pro
}

extension DeviceModel {

    public enum Ear1: Sendable, Equatable {
        case black
        case white
    }

    public enum Ear2: Sendable, Equatable {
        case black
        case white
    }

    public enum Ear3: Sendable, Equatable {
        case black
        case white
    }

    public enum Ear: Sendable, Equatable {
        case black
        case white
    }

    public enum EarA: Sendable, Equatable {
        case black
        case white
        case yellow
    }

    public enum Headphone1: Sendable, Equatable {
        case black
        case grey
    }

    public enum CMFBudsPro: Sendable, Equatable {
        case orange
        case white
        case black
    }

    public enum CMFBuds: Sendable, Equatable {
        case black
        case orange
        case white
    }

    public enum CMFBuds2: Sendable, Equatable {
        case lightGreen
        case orange
        case darkGrey
    }

    public enum CMFBuds2Plus: Sendable, Equatable {
        case blue
        case lightGrey
    }

    public enum CMFBuds2a: Sendable, Equatable {
        case lightGrey
        case orange
        case darkGrey
    }

    public enum CMFBudsPro2: Sendable, Equatable {
        case black
        case blue
        case orange
        case white
    }

    public enum CMFNeckbandPro: Sendable, Equatable {
        case black
        case orange
        case white
    }

    public enum CMFHeadphonePro: Sendable, Equatable {
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
            case .cmfBuds2a: return "CMF Buds 2a"
            case .cmfBuds2: return "CMF Buds 2"
            case .cmfBuds2Plus: return "CMF Buds 2 Plus"
            case .cmfBudsPro2: return "CMF Buds Pro 2"
            case .cmfNeckbandPro: return "CMF Neckband Pro"
            case .cmfHeadphonePro: return "CMF Headphone Pro"
        }
    }

    public var code: String {
        switch self {
            case .ear1: "B181"
            case .ear2: "B155"
            case .ear3: "B173"
            case .earStick: "B157"
            case .earOpen: "B174"
            case .ear: "B171"
            case .earA: "B162"
            case .headphone1: "B170"
            case .cmfBudsPro: "B163"
            case .cmfBuds: "B168"
            case .cmfBuds2a: "B185"
            case .cmfBuds2: "B179"
            case .cmfBuds2Plus: "B184"
            case .cmfBudsPro2: "B172"
            case .cmfNeckbandPro: "B164"
            case .cmfHeadphonePro: "B175"
        }
    }

    public var isCMF: Bool {
        switch self {
            case .cmfBudsPro,
                  .cmfBuds,
                  .cmfBuds2a,
                  .cmfBuds2,
                  .cmfBuds2Plus,
                  .cmfBudsPro2,
                  .cmfNeckbandPro,
                  .cmfHeadphonePro:
                return true
            default:
                return false
        }
    }
}

// MARK: Capabilities

extension DeviceModel {

    public var supportsNoiseCancellation: Bool {
        NoiseCancellationMode.isSupported(by: self)
    }

    public var supportsSpatialAudio: Bool {
        SpatialAudioMode.isSupported(by: self)
    }

    public var supportsEnhancedBass: Bool {
        EnhancedBass.isSupported(by: self)
    }

    public var supportsEQ: Bool {
        EQPreset.isSupported(by: self)
    }

    public var supportsCustomEQ: Bool {
        EQPreset.allSupported(by: self).contains(.custom)
    }

    public var supportsRingBuds: Bool {
        RingBuds.isSupported(by: self)
    }
}

// MARK: Model Detection

extension DeviceModel {

    static func getModel(for deviceName: String, serialNumber: String) -> Self? {
        // Try to detect model by name without color
        let modelByName: Self? = switch deviceName {
            case "Nothing Ear (1)": .ear1(.black)
            case "Nothing Ear (2)": .ear2(.black)
            case "Nothing Ear (3)": .ear3(.black)
            case "Nothing Ear (stick)": .earStick
            case "Nothing Ear (open)": .earOpen
            case "Nothing Ear": .ear(.black)
            case "Nothing Ear (a)": .earA(.black)
            case "Nothing Headphone (1)": .headphone1(.black)
            case "CMF Buds Pro": .cmfBudsPro(.black)
            case "CMF Buds": .cmfBuds(.black)
            case "CMF Buds 2A", "CMF Buds 2a": .cmfBuds2a(.darkGrey)
            case "CMF Buds 2": .cmfBuds2(.darkGrey)
            case "CMF Buds 2 Plus": .cmfBuds2Plus(.lightGrey)
            case "CMF Buds Pro 2": .cmfBudsPro2(.black)
            case "CMF Neckband Pro": .cmfNeckbandPro(.black)
            case "CMF Headphone Pro": .cmfHeadphonePro(.darkGrey)
            default: nil
        }

        // Try to detect model by serial with color
        let modelBySerial = getModel(from: serialNumber)

        guard let modelBySerial else {
            return modelByName
        }

        guard let modelByName else {
            return modelBySerial
        }

        guard Self.isBaseEqual(lhs: modelByName, rhs: modelBySerial) else {
            return modelByName
        }

        return modelBySerial
    }

    static func getModel(from serialNumber: String) -> Self? {
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
            case "99":
                .cmfBuds2(.darkGrey)
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

extension DeviceModel {

    static func isBaseEqual(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.ear1, .ear1): true
            case (.ear2, .ear2): true
            case (.ear3, .ear3): true
            case (.earStick, .earStick): true
            case (.earOpen, .earOpen): true
            case (.ear, .ear): true
            case (.earA, .earA): true
            case (.headphone1, .headphone1): true
            case (.cmfBudsPro, .cmfBudsPro): true
            case (.cmfBuds, .cmfBuds): true
            case (.cmfBuds2a, .cmfBuds2a): true
            case (.cmfBuds2, .cmfBuds2): true
            case (.cmfBuds2Plus, .cmfBuds2Plus): true
            case (.cmfBudsPro2, .cmfBudsPro2): true
            case (.cmfNeckbandPro, .cmfNeckbandPro): true
            case (.cmfHeadphonePro, .cmfHeadphonePro): true
            default: false
        }
    }
}
