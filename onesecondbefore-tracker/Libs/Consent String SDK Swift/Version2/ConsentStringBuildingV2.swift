
import Foundation

public protocol ConsentStringBuildingV2 {
    func build(
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
    ) throws -> String

    /// Helper build method that set default values for some fields
    ///
    /// The following fields will have default values
    /// - **created**, **updates** will be set to current date
    /// - **maxVendorIdForConsents** and **maxVendorIdForLegitimateInterests** will be derived from **allowedVendorIds** and **legitimateInterestsForVendorIds** respectively
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
    ) throws -> String
}

