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


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Imports

#import <Foundation/Foundation.h>
#import "OHHTTPStubsResponse.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Types

typedef BOOL(^OHHTTPStubsTestBlock)(NSURLRequest* request);
typedef OHHTTPStubsResponse*(^OHHTTPStubsResponseBlock)(NSURLRequest* request);

@protocol OHHTTPStubsDescriptor
/*! Arbitrary name that you can set and get to describe your stub. Use it as your own convenience. */
@property(nonatomic, strong) NSString* name;
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

/*! Stubs Manager. Use this class to add and remove stubs and stub your network requests. */
@interface OHHTTPStubs : NSObject

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Adding & Removing stubs

/*! Dedicated method to add a stub
 @param testBlock Block that should return `YES` if the request passed as parameter should be stubbed with the response block,
                  and `NO` if it should hit the real world (or be managed by another stub).
 @param responseBlock Block that will return the `OHHTTPStubsResponse` (response to use for stubbing) corresponding to the given request
 @return a stub descriptor that uniquely identifies the stub and can be later used to remove it with `removeStub:`.
 @note The returned stub descriptor is retained (`__strong` reference) by `OHHTTPStubs` until it is removed
       (with one of the `removeStub:`/`removeLastStub`/`removeAllStubs` methods); it is thus recommended to
       keep it in a `__weak` storage (and not `__strong`) in your app code, to let the stub descriptor be destroyed
       and let the variable go back to `nil` automatically when the stub is removed.
 */
+(id<OHHTTPStubsDescriptor>)stubRequestsPassingTest:(OHHTTPStubsTestBlock)testBlock
                                   withStubResponse:(OHHTTPStubsResponseBlock)responseBlock;

/*! Remove a stub from the list of stubs
 @param stubDesc the stub descriptor that has been returned when adding the stub using `stubRequestsPassingTest:withStubResponse:`
 @return `YES` if the stub has been successfully removed, `NO` if the parameter was not a valid stub identifier
 */
+(BOOL)removeStub:(id<OHHTTPStubsDescriptor>)stubDesc;

/*! Remove the last added stub from the stubs list */
+(void)removeLastStub;

/*! Remove all the stubs from the stubs list. */
+(void)removeAllStubs;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Disabling & Re-Enabling stubs

/*! Enable or disable the stubs
 @param enabled if `YES`, enables the stubs. If `NO`, disable all the stubs and let all the requests hit the real world.
 @note OHHTTPStubs are enabled by default, so there is no need to call this method with `YES` for stubs to work,
       except if you explicitely disabled the stubs before.
 @note This only affects requests that are further made using `NSURLConnection` or using `[NSURLSession sharedSession]`.
       This does not affect requests sent on an `NSURLSession` created using an `NSURLSessionConfiguration`.
 */
+(void)setEnabled:(BOOL)enabled;

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) \
 || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
/*!
 @param enabled If `YES`, enables the stubs for this `NSURLSessionConfiguration`.
                If `NO`, disable the stubs and let all the requests hit the real world
 @param sessionConfig The NSURLSessionConfiguration on which to enabled/disable the stubs
 @note OHHTTPStubs are enabled by default on newly created `defaultSessionConfiguration` and `ephemeralSessionConfiguration`,
         so there is no need to call this method with `YES` for stubs to work. You generally only use this if you want to
         disable `OHTTPStubs` per `NSURLSession` by calling it before building the `NSURLSession` with the `NSURLSessionConfiguration`.
 @note Important: As usual according to the way `NSURLSessionConfiguration` works, you must set this property
         *before* creating the `NSURLSession`. Once the `NSURLSession` object is created, they use a deep copy of
         the `NSURLSessionConfiguration` object used to create them, so changing the configuration later does not
         affect already created sessions.
 */
+ (void)setEnabled:(BOOL)enabled forSessionConfiguration:(NSURLSessionConfiguration *)sessionConfig;
#endif

#pragma mark - Debug Methods

/*! List all the installed stubs
 @return An array of id<OHHTTPStubsDescriptor> objects currently installed. Useful for debug.
 */
+(NSArray*)allStubs;

/*! Setup a block to be called each time a stub is triggered.
 
 Useful if you want to log all your requests being stubbed for example and see which stub was used to respond to each request.
  @param block The block to call each time a request is being stubbed by OHHTTPStubs. Set it to `nil` to do nothing. Defaults is `nil`.
 */
+(void)onStubActivation:( void(^)(NSURLRequest* request, id<OHHTTPStubsDescriptor> stub) )block;

@end

