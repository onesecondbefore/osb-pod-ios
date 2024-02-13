#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SPTIabPublisherRestriction.h"
#import "SPTIabTCFApi.h"
#import "SPTIabTCFModel.h"
#import "SPTIabTCFv1StorageProtocol.h"
#import "SPTIabTCFv1StorageUserDefaults.h"
#import "SPTIabTCFv1Types.h"
#import "SPTIabTCFv2StorageProtocol.h"
#import "SPTIabTCFv2StorageUserDefaults.h"
#import "SPTIabTCFv2Types.h"
#import "SPTIabTCStringParser.h"
#import "SPTIabTCFConstants.h"
#import "SPTIabTCFUtils.h"
#import "OSB.h"

FOUNDATION_EXPORT double onesecondbefore_trackerVersionNumber;
FOUNDATION_EXPORT const unsigned char onesecondbefore_trackerVersionString[];

