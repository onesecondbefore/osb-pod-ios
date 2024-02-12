
import Foundation

extension NSRange {
    enum V2 {
        static let version = NSRange(location: 0, length: 6)
        static let created = NSRange(location: 6, length: 36)
        static let updated = NSRange(location: 42, length: 36)
        static let cmpIdentifier = NSRange(location: 78, length: 12)
        static let cmpVersion = NSRange(location: 90, length: 12)
        static let consentScreen = NSRange(location: 102, length: 6)
        static let consentLanguage = NSRange(location: 108, length: 12)
        static let vendorListVersion = NSRange(location: 120, length: 12)
        static let tcfPolicyVersion = NSRange(location: 132, length: 6)
        static let isServiceSpecific = NSRange(location: 138, length: 1)
        static let useNonStandardTexts = NSRange(location: 139, length: 1)
        static let specialFeatureOptIns = NSRange(location: 140, length: 12)
        static let purposesConsent = NSRange(location: 152, length: 24)
        static let purposesLITransparency = NSRange(location: 176, length: 24)
        static let purposeOneTreatment = NSRange(location: 200, length: 1)
        static let publisherCC = NSRange(location: 201, length: 12)
        static let maxVendorIdentifierForConsent = NSRange(location: 213, length: 16)
        static let encodingTypeForVendorConsents = NSRange(location: 229, length: 1)
        static let numEntriesForVendorConsent = NSRange(location: 230, length: 12)
        
        // Publisher TC segment
        static let pubPurposesConsent = NSRange(location: 3, length: 24)
        static let pubPurposeLegitimateInterests = NSRange(location: 27, length: 24)

//
//        static int PUBLISHER_NUM_CUSTOM_PURPOSES_BIT_OFFSET = 51;
//        static int PUBLISHER_NUM_CUSTOM_PURPOSES_BIT_LENGTH = 6;
    }
}
