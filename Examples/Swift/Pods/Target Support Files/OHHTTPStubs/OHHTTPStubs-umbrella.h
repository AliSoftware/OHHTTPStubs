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

#import "HTTPStubs.h"
#import "OHHTTPStubsResponse.h"
#import "Compatibility.h"
#import "OHHTTPStubsResponse+JSON.h"
#import "NSURLRequest+HTTPBodyTesting.h"
#import "OHPathHelpers.h"
#import "Compatibility.h"

FOUNDATION_EXPORT double OHHTTPStubsVersionNumber;
FOUNDATION_EXPORT const unsigned char OHHTTPStubsVersionString[];

