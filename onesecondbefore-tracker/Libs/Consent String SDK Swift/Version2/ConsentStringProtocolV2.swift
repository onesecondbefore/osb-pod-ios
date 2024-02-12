
import Foundation

public typealias PurposeIdentifier = Int16
public typealias FeatureIdentifier = Int16
public typealias PubPurposeIdentifier = Int16

public protocol ConsentStringV2Protocol {

    init(consentString: String) throws

    var dateCreated: Date { get }
    var dateUpdated: Date { get }

    var consentString: String { get set }
    var cmpId: Int { get }
    var consentScreen: Int { get }
    var consentLanguage: String { get }

    var publisherCC: String { get }
    var vendorListVersion: Int8 { get }

    var tfcPolicyVersion: Int8 { get }
    var isServiceSpecific: Int8 { get }
    var useNonStandardTexts: Int8 { get }
    var purposeOneTreatment: Int8 { get }

    var specialFeatureOptIns: Set<FeatureIdentifier> { get }

    var purposeConsents: Set<PurposeIdentifier> { get }
    func purposeConsent(forPurposeId purposeId: PurposeIdentifier) -> Bool

    var purposeLegitimateInterests: Set<PurposeIdentifier> { get }
    func purposeLegitimateInterest(forPurposeId purposeId: PurposeIdentifier) -> Bool

    var maxVendorIdForConsents: VendorIdentifier { get }
    func isVendorAllowed(vendorId: VendorIdentifier) -> Bool

    var maxVendorIdForLegitimateInterests: VendorIdentifier { get }
    func isLegitimateInterestForVendorAllowed(vendorId: VendorIdentifier) -> Bool
}
