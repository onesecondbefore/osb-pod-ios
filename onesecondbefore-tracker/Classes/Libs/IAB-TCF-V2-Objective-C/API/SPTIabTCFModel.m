//
//  SPTIabTCFModelV1.m
//  SPTProximityKit
//
//  Created by Quentin Beaudouin on 04/06/2020.
//  Copyright © 2020 Alexandre Fortoul. All rights reserved.
//

#import "SPTIabTCFModel.h"

@implementation SPTIabTCFModel

- (BOOL)isVendorConsentGivenFor:(int)vendorId {
    return [self booleanInBitString:self.parsedVendorConsents forId:vendorId];
}

- (BOOL)isVendorLegitInterestGivenFor:(int)vendorId {
    return [self booleanInBitString:self.parsedVendorLegitmateInterest forId:vendorId];
}

- (BOOL)isPurposeConsentGivenFor:(int)purposeId {
    return [self booleanInBitString:self.parsedPurposeConsents forId:purposeId];
}

- (BOOL)isPurposeLegitInterestGivenFor:(int)purposeId {
    return [self booleanInBitString:self.parsedPurposeLegitmateInterest forId:purposeId];
}

- (BOOL)isSpecialFeatureOptedInFor:(int)specialFeatureId {
     return [self booleanInBitString:self.specialFeatureOptIns forId:specialFeatureId];
}

- (BOOL)isVendorDiscloseFor:(int)vendorId {
    return [self booleanInBitString:self.parsedDisclosedVendors forId:vendorId];
}

- (BOOL)isVendorAllowedFor:(int)vendorId {
    return [self booleanInBitString:self.parsedAllowedVendors forId:vendorId];
}

- (BOOL)isPublisherPurposeConsentGivenFor:(int)purposeId {
    return [self booleanInBitString:self.publisherTCParsedPurposesConsents forId:purposeId];
}

- (BOOL)isPublisherPurposeLegitInterestGivenFor:(int)purposeId {
    return [self booleanInBitString:self.publisherTCParsedPurposesLegitmateInterest forId:purposeId];
}

- (BOOL)isPublisherCustomPurposeConsentGivenFor:(int)purposeId {
    return [self booleanInBitString:self.publisherTCParsedCustomPurposesConsents forId:purposeId];
}

- (BOOL)isPublisherCustomPurposeLegitInterestGivenFor:(int)purposeId {
    return [self booleanInBitString:self.publisherTCParsedCustomPurposesLegitmateInterest forId:purposeId];
}

- (PublisherRestrictionType)publisherRestrictionTypeForVendor:(int)vendorId forPurpose:(int)purposeId {
    
    NSString *parsedVendorsPubRest = @"";
    for (SPTIabPublisherRestriction *pubRest in self.publisherRestrictions) {
        if (pubRest.purposeId == purposeId) {
            parsedVendorsPubRest =  pubRest.parsedVendors;
        }
    }
    if (!parsedVendorsPubRest || parsedVendorsPubRest.length == 0 || parsedVendorsPubRest.length < vendorId) {
        return Restriction_Undefined;
    }
    NSInteger restIntvalue = [[parsedVendorsPubRest substringWithRange:NSMakeRange(vendorId-1, 1)] integerValue];
    
    return restIntvalue;
}

- (BOOL)booleanInBitString:(NSString *)bitSstring forId:(int)index {
    if (!bitSstring || bitSstring.length == 0 || bitSstring.length < index) {
        return NO;
    }
    
    return [[bitSstring substringWithRange:NSMakeRange(index-1, 1)] boolValue];
}

- (NSDictionary *)asJson {
    
    NSMutableDictionary * result = [NSMutableDictionary new];

    [result setValue:@(self.version) forKey:@"version"];
    [result setValue:self.created forKey:@"created"];
    [result setValue:self.lastUpdated forKey:@"lastUpdated"];
    [result setValue:@(self.cmpId) forKey:@"cmpId"];
    [result setValue:@(self.cmpVersion) forKey:@"cmpVersion"];
    [result setValue:@(self.consentScreen) forKey:@"consentScreen"];
    [result setValue:self.consentCountryCode forKey:@"consentCountryCode"];
    [result setValue:@(self.vendorListVersion) forKey:@"vendorListVersion"];
    [result setValue:self.parsedPurposeConsents forKey:@"parsedPurposesConsents"];
    [result setValue:self.parsedVendorConsents forKey:@"parsedVendorsConsents"];
    
    [result setValue:self.parsedPurposeLegitmateInterest forKey:@"parsedPurposesLegitmateInterest"];
    [result setValue:self.parsedVendorLegitmateInterest forKey:@"parsedVendorsLegitmateInterest"];
    [result setValue:@(self.policyVersion) forKey:@"policyVersion"];
    [result setValue:@(self.isServiceSpecific) forKey:@"isServiceSpecific"];
    [result setValue:@(self.useNonStandardStack) forKey:@"useNonStandardStack"];
    [result setValue:self.specialFeatureOptIns forKey:@"specialFeatureOptIns"];
    [result setValue:@(self.purposeOneTreatment) forKey:@"purposeOneTreatment"];
    [result setValue:self.publisherCountryCode forKey:@"publisherCountryCode"];
    
    [result setValue:self.parsedDisclosedVendors forKey:@"parsedDisclosedVendors"];
    [result setValue:self.parsedAllowedVendors forKey:@"parsedAllowedVendors"];
    
    [result setValue:self.publisherTCParsedPurposesConsents forKey:@"publisherTCParsedPurposesConsents"];
    [result setValue:self.publisherTCParsedPurposesLegitmateInterest forKey:@"publisherTCParsedPurposesLegitmateInterest"];
    [result setValue:self.publisherTCParsedCustomPurposesConsents forKey:@"publisherTCParsedCustomPurposesConsents"];
    [result setValue:self.publisherTCParsedCustomPurposesLegitmateInterest forKey:@"publisherTCParsedCustomPurposesLegitmateInterest"];
    
    
    NSMutableArray * pubRestArray = [[NSMutableArray alloc] initWithCapacity:self.publisherRestrictions.count];
    for (SPTIabPublisherRestriction *rest in self.publisherRestrictions) {
        [pubRestArray addObject:[rest asJson]];
    }
    
    [result setValue:pubRestArray forKey:@"publisherRestrictions"];

    return result;
}

-(NSUInteger)hash {
    return [self asJson].hash;
}

@end
