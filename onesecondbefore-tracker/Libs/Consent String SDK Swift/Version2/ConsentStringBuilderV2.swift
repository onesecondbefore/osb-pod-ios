
import Foundation

public class ConsentStringBuilderV2: ConsentStringBuildingV2 {

    enum Error: Swift.Error {
        case invalidLanguageCode(String)
    }

    private let version: Int = 2
    private let asciiOffset: UInt8 = 65
    let now: () -> Date

    public init(now: @escaping () -> Date = { Date() }) {
        self.now = now
    }

    /// Build a v2 consent string
    /// Disclosed vendors and  publishers' restirctions are not supported
    public func build(
        created: Date,
        updated: Date,
        cmpId: Int,
        cmpVersion: Int,
        consentScreenId: Int,
        consentLanguage: String,
        vendorListVersion: UInt8,
        tcfPolicyVersion: UInt8,
        isServiceSpecific: UInt8,
        useNonStandardTexts: UInt8,
        specialFeatureOptIns: Set<FeatureIdentifier>,
        purposeConsents: Set<PurposeIdentifier>,
        purposeLegitimateInterests: Set<PurposeIdentifier>,
        purposeOneTreatment: UInt8,
        publisherCC: String,
        maxVendorIdForConsents: VendorIdentifier,
        allowedVendorIds: Set<VendorIdentifier>,
        maxVendorIdForLegitimateInterests: VendorIdentifier,
        legitimateInterestsForVendorIds: Set<VendorIdentifier>
    ) throws -> String {
        var consentString = ""
        consentString.append(encode(integer: version, toLength: NSRange.V2.version.length))
        consentString.append(encode(date: created, toLength: NSRange.V2.created.length))
        consentString.append(encode(date: updated, toLength: NSRange.V2.updated.length))
        consentString.append(encode(integer: cmpId, toLength: NSRange.V2.cmpIdentifier.length))
        consentString.append(encode(integer: cmpVersion, toLength: NSRange.V2.cmpVersion.length))
        consentString.append(encode(integer: consentScreenId, toLength: NSRange.V2.consentScreen.length))

        guard consentLanguage.count == 2,
              let firstLanguageCharacter = consentLanguage.uppercased()[consentLanguage.index(consentLanguage.startIndex, offsetBy: 0)].asciiValue,
              firstLanguageCharacter >= asciiOffset,
              let secondLanguageCharacter = consentLanguage.uppercased()[consentLanguage.index(consentLanguage.startIndex, offsetBy: 1)].asciiValue,
              secondLanguageCharacter >= asciiOffset else {
            throw Error.invalidLanguageCode(consentLanguage)
        }

        consentString.append(encode(integer: firstLanguageCharacter - asciiOffset, toLength: NSRange.V2.consentLanguage.length / 2))
        consentString.append(encode(integer: secondLanguageCharacter - asciiOffset, toLength: NSRange.V2.consentLanguage.length / 2))
        consentString.append(encode(integer: vendorListVersion, toLength: NSRange.V2.vendorListVersion.length))

        consentString.append(encode(integer: tcfPolicyVersion, toLength: NSRange.V2.tcfPolicyVersion.length))
        consentString.append(encode(integer: isServiceSpecific, toLength: NSRange.V2.isServiceSpecific.length))
        consentString.append(encode(integer: useNonStandardTexts, toLength: NSRange.V2.useNonStandardTexts.length))

        consentString.append(encode(intSet: specialFeatureOptIns, toLength: NSRange.V2.specialFeatureOptIns.length))
        consentString.append(encode(intSet: purposeConsents, toLength: NSRange.V2.purposesConsent.length))
        consentString.append(encode(intSet: purposeLegitimateInterests, toLength: NSRange.V2.purposesLITransparency.length))

        consentString.append(encode(integer: purposeOneTreatment, toLength: NSRange.V2.purposeOneTreatment.length))

        guard publisherCC.count == 2,
              let firstPubCCCharacter = publisherCC.uppercased()[publisherCC.index(publisherCC.startIndex, offsetBy: 0)].asciiValue,
              firstPubCCCharacter >= asciiOffset,
              let secondPubCCCharacter = publisherCC.uppercased()[publisherCC.index(publisherCC.startIndex, offsetBy: 1)].asciiValue,
              secondPubCCCharacter >= asciiOffset else {
            throw Error.invalidLanguageCode(publisherCC)
        }
        consentString.append(encode(integer: firstPubCCCharacter - asciiOffset, toLength: NSRange.V2.publisherCC.length / 2))
        consentString.append(encode(integer: secondPubCCCharacter - asciiOffset, toLength: NSRange.V2.publisherCC.length / 2))

        // Vendors consent
        consentString.append(encode(integer: maxVendorIdForConsents, toLength: NSRange.V2.maxVendorIdentifierForConsent.length))

        if maxVendorIdForConsents > 0 {
            let bitFieldsForVendorConsent = bitFieldBinaryString(allowedVendorIds: allowedVendorIds, maxVendorId: maxVendorIdForConsents)
            let rangesForVendorConsent = rangesBinaryString(allowedVendorIds: allowedVendorIds, maxVendorId: maxVendorIdForConsents)

            if rangesForVendorConsent.count < bitFieldsForVendorConsent.count {
                consentString.append(rangesForVendorConsent)
            } else {
                consentString.append(bitFieldsForVendorConsent)
            }
        } else {
            // IsARange value always needs to be encoded
            consentString.append(encode(integer: VendorEncodingType.bitField.rawValue, toLength: NSRange.encodingType.length))
        }

        // Vendors legitimate interest
        let maxVendorIdentifierForLegIntLength = 16
        consentString.append(encode(integer: maxVendorIdForLegitimateInterests, toLength: maxVendorIdentifierForLegIntLength))

        if maxVendorIdForLegitimateInterests > 0 {
            let bitFieldsForVendorLegitimateInterest = bitFieldBinaryString(allowedVendorIds: legitimateInterestsForVendorIds, maxVendorId: maxVendorIdForLegitimateInterests)
            let rangesForVendorLegitimateInterest = rangesBinaryString(allowedVendorIds: legitimateInterestsForVendorIds, maxVendorId: maxVendorIdForLegitimateInterests)

            if rangesForVendorLegitimateInterest.count < bitFieldsForVendorLegitimateInterest.count {
                consentString.append(rangesForVendorLegitimateInterest)
            } else {
                consentString.append(bitFieldsForVendorLegitimateInterest)
            }
        } else {
            // IsARange value always needs to be encoded
            consentString.append(encode(integer: VendorEncodingType.bitField.rawValue, toLength: NSRange.encodingType.length))
        }

        // NumPubRestrictions. 0 means no publisher's restrictions
        let numPubRestrictionsLength = 12
        consentString.append(encode(integer: 0, toLength: numPubRestrictionsLength))

        return consentString
            .padRight(toNearestMultipleOf: 8)
            .trimmedBase64EncodedString()
    }

    func bitFieldBinaryString(allowedVendorIds: Set<VendorIdentifier>, maxVendorId: VendorIdentifier) -> String {
        var consentString = ""
        consentString.append(encode(integer: VendorEncodingType.bitField.rawValue, toLength: NSRange.encodingType.length))
        consentString.append(encode(vendorBitFieldForVendors: allowedVendorIds, maxVendorId: maxVendorId))
        return consentString
    }

    func rangesBinaryString(allowedVendorIds: Set<VendorIdentifier>, maxVendorId: VendorIdentifier) -> String {
        var consentString = ""
        consentString.append(encode(integer: VendorEncodingType.range.rawValue, toLength: NSRange.encodingType.length))
        consentString.append(encode(vendorRanges: ranges(for: allowedVendorIds, in: Array(1...maxVendorId))))
        return consentString
    }

    func encode(integer: UInt8, toLength length: Int) -> String {
        return String(integer, radix: 2).padLeft(toLength: length)
    }

    func encode(integer: Int16, toLength length: Int) -> String {
        return String(integer, radix: 2).padLeft(toLength: length)
    }

    func encode(bool: Bool) -> String {
        encode(integer: bool ? 1 : 0, toLength: 1)
    }

    func encode(integer: Int, toLength length: Int) -> String {
        return String(integer, radix: 2).padLeft(toLength: length)
    }

    func encode(date: Date, toLength length: Int) -> String {
        let dayLevel = calendar.startOfDay(for: date)
        return encode(integer: Int(dayLevel.timeIntervalSince1970 * 10), toLength: length)
    }

    public func encode(purposeBitFieldForPurposes purposes: Purposes) -> String {
        return encode(integer: purposes.rawValue, toLength: NSRange.purposes.length)
    }

    public func encode(vendorBitFieldForVendors vendors: Set<VendorIdentifier>, maxVendorId: VendorIdentifier) -> String {
        return (1...maxVendorId).reduce("") { $0 + (vendors.contains($1) ? "1" : "0") }
    }

    public func encode(intSet set: Set<Int16>, toLength: Int) -> String {
        return (1...toLength).reduce("") { $0 + (set.contains(Int16($1)) ? "1" : "0") }
    }

    func encode(vendorRanges ranges: [ClosedRange<VendorIdentifier>]) -> String {
        var string = ""
        string.append(encode(integer: ranges.count, toLength: NSRange.numberOfEntries.length))
        for range in ranges {
            if range.count == 1 {
                // single entry
                string.append(encode(integer: 0, toLength: 1))
                string.append(encode(integer: range.lowerBound, toLength: ConsentString.vendorIdentifierSize))
            } else {
                // range entry
                string.append(encode(integer: 1, toLength: 1))
                string.append(encode(integer: range.lowerBound, toLength: ConsentString.vendorIdentifierSize))
                string.append(encode(integer: range.upperBound, toLength: ConsentString.vendorIdentifierSize))
            }
        }
        return string
    }

    func ranges(
        for allowedVendorIds: Set<VendorIdentifier>,
        in allVendorIds: [VendorIdentifier]
    ) -> [ClosedRange<VendorIdentifier>] {
        var ranges = [ClosedRange<VendorIdentifier>]()
        var currentRangeStart: VendorIdentifier?
        for vendorId in allVendorIds.sorted() {
            if allowedVendorIds.contains(vendorId) {
                if currentRangeStart == nil {
                    // start a new range
                    currentRangeStart = vendorId
                }
            } else if let rangeStart = currentRangeStart {
                // close the range
                ranges.append(rangeStart...vendorId-1)
                currentRangeStart = nil
            }
        }

        // close any range open at the end
        if let rangeStart = currentRangeStart, let last = allVendorIds.last {
            ranges.append(rangeStart...last)
            currentRangeStart = nil
        }
        return ranges
    }

    // MARK: - Private
    private lazy var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
}

private extension String {
    func padLeft(withCharacter character: String = "0", toLength length: Int) -> String {
        let padCount = length - count
        guard padCount > 0 else { return self }
        return String(repeating: character, count: padCount) + self
    }

    func padRight(withCharacter character: String = "0", toLength length: Int) -> String {
        let padCount = length - count
        guard padCount > 0 else { return self }
        return self + String(repeating: character, count: padCount)
    }

    func padRight(withCharacter character: String = "0", toNearestMultipleOf multiple: Int) -> String {
        let (byteCount, bitRemainder) = count.quotientAndRemainder(dividingBy: multiple)
        let totalBytes = byteCount + (bitRemainder > 0 ? 1 : 0)
        return padRight(toLength: totalBytes * multiple)
    }

    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()

        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }

    func trimmedBase64EncodedString() -> String {
        let data = Data(bytes: split(by: 8).compactMap { UInt8($0, radix: 2) })
        return data.base64EncodedString()
            .trimmingCharacters(in: ["="])
    }
}

public extension ConsentStringBuilderV2 {
    func build(
        cmpId: Int,
        cmpVersion: Int,
        consentScreenId: Int,
        consentLanguage: String,
        vendorListVersion: UInt8,
        tcfPolicyVersion: UInt8,
        useNonStandardTexts: UInt8,
        specialFeatureOptIns: Set<FeatureIdentifier>,
        purposeConsents: Set<PurposeIdentifier>,
        purposeLegitimateInterests: Set<PurposeIdentifier>,
        purposeOneTreatment: UInt8,
        publisherCC: String,
        allowedVendorIds: Set<VendorIdentifier>,
        legitimateInterestsForVendorIds: Set<VendorIdentifier>
    ) throws -> String {
        let maxVendorIdForConsents = allowedVendorIds.max() ?? 0
        let maxVendorIdForLegitimateInterests = legitimateInterestsForVendorIds.max() ?? 0
        return try self.build(
            created: now(),
            updated: now(),
            cmpId: cmpId,
            cmpVersion: cmpVersion,
            consentScreenId: consentScreenId,
            consentLanguage: consentLanguage,
            vendorListVersion: vendorListVersion,
            tcfPolicyVersion: tcfPolicyVersion,
            isServiceSpecific: 1,
            useNonStandardTexts: useNonStandardTexts,
            specialFeatureOptIns: specialFeatureOptIns,
            purposeConsents: purposeConsents,
            purposeLegitimateInterests: purposeLegitimateInterests,
            purposeOneTreatment: purposeOneTreatment,
            publisherCC: publisherCC,
            maxVendorIdForConsents: maxVendorIdForConsents,
            allowedVendorIds: allowedVendorIds,
            maxVendorIdForLegitimateInterests: maxVendorIdForLegitimateInterests,
            legitimateInterestsForVendorIds: legitimateInterestsForVendorIds
        )
    }
}
