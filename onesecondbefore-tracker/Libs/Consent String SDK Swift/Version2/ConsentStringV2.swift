
import Foundation

public class ConsentStringV2: ConsentStringV2Protocol {

    // MARK: - ConsentStringV2Protocol

    required public init(consentString: String) throws {
        self.consentString = consentString
        guard let dataValue = Data(base64Encoded: self.consentString.base64Padded) else {
            throw ConsentStringError.base64DecodingFailed
        }
        consentData = dataValue
    }

    public var consentString: String {
        //error correction in didSet resets old value if base64decoding fails
        didSet {
            guard let dataValue = Data(base64Encoded: consentString.base64Padded) else {
                print("New Consent String Value is not base64 decodable. Throwing away changes.")
                consentString = oldValue
                return
            }
            consentData = dataValue
        }
    }

    public var dateCreated: Date {
        let timeIntervalDecseconds = Int(consentData.intValue(for: NSRange.V2.created))
        let timeInterval = TimeInterval(timeIntervalDecseconds / 10)
        return Date(timeIntervalSince1970: timeInterval)
    }

    public var dateUpdated: Date {
        let timeIntervalDecseconds = Int(consentData.intValue(for: NSRange.V2.updated))
        let timeInterval = TimeInterval(timeIntervalDecseconds / 10)
        return Date(timeIntervalSince1970: timeInterval)
    }

    public var cmpId: Int {
        return Int(consentData.intValue(for: NSRange.V2.cmpIdentifier))
    }
    
    public var cmpVersion: Int {
        return Int(consentData.intValue(for: NSRange.V2.version))
    }

    public var consentScreen: Int {
        return Int(consentData.intValue(for: NSRange.V2.consentScreen))
    }

    public var consentLanguage: String {
        var data = consentData.data(for: .consentLanguage)
        data.insert(0, at: 0)
        let string = data.base64EncodedString()
        return String(string[string.index(string.startIndex, offsetBy: 2)...])
    }

    public var publisherCC: String {
        var data = consentData.data(for: NSRange.V2.publisherCC)
        data.insert(0, at: 0)
        let string = data.base64EncodedString()
        return String(string[string.index(string.startIndex, offsetBy: 2)...])
    }

    public var vendorListVersion: Int8 {
        return Int8(consentData.intValue(for: NSRange.V2.vendorListVersion))
    }

    public var tfcPolicyVersion: Int8 {
        return Int8(consentData.intValue(for: NSRange.V2.tcfPolicyVersion))
    }

    public var isServiceSpecific: Int8 {
        return Int8(consentData.intValue(for: NSRange.V2.isServiceSpecific))
    }

    public var useNonStandardTexts: Int8 {
        return Int8(consentData.intValue(for: NSRange.V2.useNonStandardTexts))
    }

    public var purposeOneTreatment: Int8 {
        return Int8(consentData.intValue(for: NSRange.V2.purposeOneTreatment))
    }

    public var specialFeatureOptIns: Set<FeatureIdentifier> {
        var result = Set<FeatureIdentifier>()
        for specialFeatureId in 1...NSRange.V2.specialFeatureOptIns.length {
            let specialFeatureBit = Int64(NSRange.V2.specialFeatureOptIns.lowerBound - 1 + specialFeatureId)
            let value = Int(consentData.intValue(fromBit: specialFeatureBit, toBit: specialFeatureBit))
            if value > 0 {
                result.insert(FeatureIdentifier(specialFeatureId))
            }
        }
        return result
    }

    public var purposeConsents: Set<PurposeIdentifier> {
        var results = Set<PurposeIdentifier>()
        for purposeId in 1...NSRange.V2.purposesConsent.length {
            let purposeBit = Int64(NSRange.V2.purposesConsent.lowerBound - 1 + purposeId)
            let value = Int(consentData.intValue(fromBit: purposeBit, toBit: purposeBit))
            if value > 0 {
                results.insert(PurposeIdentifier(purposeId))
            }
        }
        return results
    }
    
    
    public func purposeConsent(forPurposeId purposeId: PurposeIdentifier) -> Bool {
        purposeConsents.contains(purposeId)
    }

    public var purposeLegitimateInterests: Set<PurposeIdentifier> {
        var result = Set<PurposeIdentifier>()
        for purposeLegIntId in 1...NSRange.V2.purposesLITransparency.length {
            let purposeLegIntBit = Int64(NSRange.V2.purposesLITransparency.lowerBound - 1 + purposeLegIntId)
            let value = Int(consentData.intValue(fromBit: purposeLegIntBit, toBit: purposeLegIntBit))
            if value > 0 {
                result.insert(PurposeIdentifier(purposeLegIntId))
            }
        }
        return result
    }

    public func purposeLegitimateInterest(forPurposeId purposeId: PurposeIdentifier) -> Bool {
        purposeLegitimateInterests.contains(purposeId)
    }

    public var maxVendorIdForConsents: VendorIdentifier {
        return VendorIdentifier(consentData.intValue(for: NSRange.V2.maxVendorIdentifierForConsent))
    }

    public func isVendorAllowed(vendorId: VendorIdentifier) -> Bool {
        if vendorId > maxVendorIdForConsents {
            return false
        }
        let isRange = consentData.intValue(for: NSRange.V2.encodingTypeForVendorConsents) == 1
        if isRange {
            let vendorIdentifierSize = Int64(ConsentString.vendorIdentifierSize)
            let consentDataMaxBit = consentData.count * 8 - 1
            let rangesCount = Int(consentData.intValue(for: NSRange.V2.numEntriesForVendorConsent))
            var rangeStart = Int64(NSRange.V2.numEntriesForVendorConsent.location + NSRange.V2.numEntriesForVendorConsent.length)
            for _ in 0..<rangesCount {
                let entryType = consentData.intValue(fromBit: rangeStart, toBit: rangeStart)
                if consentDataMaxBit < rangeStart + 1 + vendorIdentifierSize + (entryType * vendorIdentifierSize) { //typebit + either 16 or 32
                    return false
                }
                if entryType == 0 {
                    let thisVendorId = consentData.intValue(fromBit: rangeStart + 1, toBit: rangeStart + vendorIdentifierSize)
                    if vendorId == thisVendorId {
                        return true
                    }
                    rangeStart += 17
                } else if entryType == 1 {
                    let vendorStart = consentData.intValue(fromBit: rangeStart + 1, toBit: rangeStart + vendorIdentifierSize)
                    let vendorFinish = consentData.intValue(fromBit: rangeStart + 1 + vendorIdentifierSize + 1, toBit: rangeStart + vendorIdentifierSize * 2)
                    if vendorStart <= vendorId && vendorId <= vendorFinish {
                        //if vendorId falls within range, then return opposite of default consent
                        return true
                    }
                    rangeStart += 33
                }
            }
            return false
        } else {
            let vendorBitField = Int64(ConsentStringV2.bitFieldVendorConsentStart) + Int64(vendorId) - 1
            // not enough bits
            guard vendorBitField < consentData.count * 8 else {
                return false
            }
            let value = consentData.intValue(fromBit: vendorBitField, toBit: vendorBitField)
            if value == 0 {
                return false
            } else {
                return true
            }
        }
    }

    public var maxVendorIdForLegitimateInterests: VendorIdentifier {
        let maxVendorIdForLegInt = VendorIdentifier(consentData.intValue(for: NSRange(location: startOfVendorLegitimateInterestSection, length: 16)))
        return maxVendorIdForLegInt
    }

    public func isLegitimateInterestForVendorAllowed(vendorId: VendorIdentifier) -> Bool {
        let maxVendorIdForLegIntLocation = startOfVendorLegitimateInterestSection
        let maxVendorIdForLegInt = Int(consentData.intValue(for: NSRange(location: maxVendorIdForLegIntLocation, length: 16)))
        if vendorId > maxVendorIdForLegInt {
            return false
        }

        let isRangeForLegIntLocation = maxVendorIdForLegIntLocation + 16
        let isRange = consentData.intValue(for: NSRange(location: isRangeForLegIntLocation, length: 1)) == 1
        if isRange {
            let vendorIdentifierSize = Int64(ConsentString.vendorIdentifierSize)
            let consentDataMaxBit = consentData.count * 8 - 1
            let ragesCountRange = NSRange(location: isRangeForLegIntLocation + 1, length: 12)
            let rangesCount = Int(consentData.intValue(for: ragesCountRange))
            var rangeStart = Int64(ragesCountRange.location + ragesCountRange.length)
            for _ in 0..<rangesCount {
                let entryType = consentData.intValue(fromBit: rangeStart, toBit: rangeStart)
                if consentDataMaxBit < rangeStart + 1 + vendorIdentifierSize + (entryType * vendorIdentifierSize) { //typebit + either 16 or 32
                    return false
                }
                if entryType == 0 {
                    let thisVendorId = consentData.intValue(fromBit: rangeStart + 1, toBit: rangeStart + vendorIdentifierSize)
                    if vendorId == thisVendorId {
                        return true
                    }
                    rangeStart += 17
                } else if entryType == 1 {
                    let vendorStart = consentData.intValue(fromBit: rangeStart + 1, toBit: rangeStart + vendorIdentifierSize)
                    let vendorFinish = consentData.intValue(fromBit: rangeStart + 1 + vendorIdentifierSize + 1, toBit: rangeStart + vendorIdentifierSize * 2)
                    if vendorStart <= vendorId && vendorId <= vendorFinish {
                        //if vendorId falls within range, then return opposite of default consent
                        return true
                    }
                    rangeStart += 33
                }
            }
            return false
        } else {
            let bitFieldsStartLocation = isRangeForLegIntLocation + 1
            let vendorBitField = Int64(bitFieldsStartLocation) + Int64(vendorId) - 1
            //not enough bits
            guard vendorBitField < consentData.count * 8 else {
                return false
            }
            let value = consentData.intValue(fromBit: vendorBitField, toBit: vendorBitField)
            if value == 0 {
                return false
            } else {
                return true
            }
        }
    }
    
    
    public func setPublisherTC(publisherTCString: String) throws {
//        print(publisherTCString)
//        guard let dataValue = Data(base64Encoded: publisherTCString.base64Padded) else {
//            throw ConsentStringError.base64DecodingFailed
//        }
        publisherTCData = publisherTCString.data(using: .utf8)
    }

//    var publisherLegitimateInterests: Int {
//        guard let publisherTCData = self.publisherTCData else {
//            print("OSB Error: Could not parse PublisherTCData.")
//            return 0
//        }
//        return Int(publisherTCData.intValue(for: NSRange.V2.publisherLegitimateInterests))
//    }
    
    public var publisherLegitimateInterests: Set<PubPurposeIdentifier> {
        var result = Set<PubPurposeIdentifier>()
        guard let publisherTCData = self.publisherTCData else {
            print("OSB Error: PublisherTCData not set.")
            return result
        }
        for purposeLegIntId in 1...NSRange.V2.pubPurposeLegitimateInterests.length {
            let purposeLegIntBit = Int64(NSRange.V2.pubPurposeLegitimateInterests.lowerBound - 1 + purposeLegIntId)
            let value = Int(publisherTCData.intValue(fromBit: purposeLegIntBit, toBit: purposeLegIntBit))
            if value > 0 {
                result.insert(PubPurposeIdentifier(purposeLegIntId))
            }
        }
        return result
    }
    
    public func publisherLegitimateInterest(forPubPurposeId purposeId: PubPurposeIdentifier) -> Bool {
        publisherLegitimateInterests.contains(purposeId)
    }
    
    public var pubPurposeConsents: Set<PubPurposeIdentifier> {
        var result = Set<PubPurposeIdentifier>()
        guard let publisherTCData = self.publisherTCData else {
            print("OSB Error: PublisherTCData not set.")
            return result
        }
        
        for purposeId in 1...NSRange.V2.pubPurposesConsent.length {
            let purposeBit = Int64(NSRange.V2.pubPurposesConsent.lowerBound - 1 + purposeId)
            let value = Int(publisherTCData.intValue(fromBit: purposeBit, toBit: purposeBit))
            if value > 0 {
                result.insert(PubPurposeIdentifier(purposeId))
            }
        }
        return result
    }

    public func pubPurposeConsent(forPubPurposeId purposeId: PubPurposeIdentifier) -> Bool {
        pubPurposeConsents.contains(purposeId)
    }

    // MARK: - Internal

    static let bitFieldVendorConsentStart: Int = 230
    static let rangeEntryOffset: Int = 186
    static let vendorIdentifierSize: Int = 16

    var consentData: Data
    var publisherTCData: Data?
    

    private var startOfVendorLegitimateInterestSection: Int {
        let isRange = consentData.intValue(for: NSRange.V2.encodingTypeForVendorConsents) == 1
        if isRange {
            let rangesCount = Int(consentData.intValue(for: NSRange.V2.numEntriesForVendorConsent))
            var result = Int64(NSRange.V2.numEntriesForVendorConsent.location + NSRange.V2.numEntriesForVendorConsent.length)
            for _ in 0..<rangesCount {
                let entryType = consentData.intValue(fromBit: result, toBit: result)
                if entryType == 0 {
                    result += 17
                } else {
                    result += 33
                }
            }
            return Int(result)
        } else {
            return NSRange.V2.encodingTypeForVendorConsents.location
                + 1
                + Int(maxVendorIdForConsents)
        }
    }
}

