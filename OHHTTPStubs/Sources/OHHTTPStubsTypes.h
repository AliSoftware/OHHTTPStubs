/***********************************************************************************
 *
 * Copyright (c) 2012 Olivier Halligon
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 ***********************************************************************************/

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

typedef void(^OHHTTPStubsActivationBlock)(NSURLRequest* request, id<OHHTTPStubsDescriptor> stub, OHHTTPStubsResponse* responseStub);
typedef void(^OHHTTPStubsRedirectBlock)(NSURLRequest* request, NSURLRequest* redirectRequest, id<OHHTTPStubsDescriptor> stub, OHHTTPStubsResponse* responseStub);
typedef void(^OHHTTPStubsFinishBlock)(NSURLRequest* request, id<OHHTTPStubsDescriptor> stub, OHHTTPStubsResponse* responseStub, NSError *error);

NS_ASSUME_NONNULL_END
