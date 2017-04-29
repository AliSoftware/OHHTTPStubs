//
//  OHHTTPStubsTypes.h
//  OHHTTPStubs
//
//  Created by Nickolas Pohilets on 29.04.17.
//  Copyright © 2017 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OHHTTPStubsResponse.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^OHHTTPStubsTestBlock)(NSURLRequest* request);
typedef OHHTTPStubsResponse* __nonnull (^OHHTTPStubsResponseBlock)( NSURLRequest* request);

/**
 *  This opaque type represents an installed stub and is used to uniquely
 *  identify a stub once it has been created.
 *
 *  This type is returned by the `stubRequestsPassingTest:withStubResponse:` method
 *  so that you can later reference it and use this reference to remove the stub later.
 *
 *  This type also let you add arbitrary metadata to a stub to differenciate it
 *  more easily when debugging.
 */
@protocol OHHTTPStubsDescriptor <NSObject>
/**
 *  An arbitrary name that you can set and get to describe your stub.
 *  Use it as your own convenience.
 *
 *  This is especially useful if you dump all installed stubs using `allStubs`
 *  or if you want to log which stubs are being triggered using `onStubActivation:`.
 */
@property(nonatomic, strong, nullable) NSString* name;

@end

NS_ASSUME_NONNULL_END
