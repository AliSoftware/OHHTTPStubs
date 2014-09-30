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


/*----------------------------------------------------------------------------------
 * NOTE
 *
 * This file mirror the new XCTestExpectation API from Xcode 6's XCTest framework
 * (at least part of it) so that we can use the same API in older Xcode versions
 ----------------------------------------------------------------------------------*/

#if XCODE_VERSION < 0600

#define XCTestExpectation_OHRetroCompat_BETTER_FAILURE_LOCATIONS 1

#import <XCTest/XCTest.h>

///////////////////////////////////////////////////////////////////////////////////

@interface XCTestExpectation : NSObject

/*!
 * @method -fulfill
 *
 * @discussion
 * Call -fulfill to mark an expectation as having been met. It's an error to call
 * -fulfill on an expectation that has already been fulfilled or when the test case
 * that vended the expectation has already completed.
 */
-(void)fulfill;

@end

/////////////////////////////////////////////////////////

@interface XCTestCaseAsync : XCTestCase

/*!
 * @method +expectationWithDescription:
 *
 * @param description
 * This string will be displayed in the test log to help diagnose failures.
 *
 * @discussion
 * Creates and returns an expectation associated with the test case.
 */
- (XCTestExpectation *)expectationWithDescription:(NSString *)description;

/*!
 * @typedef XCWaitCompletionHandler
 * A block to be invoked when a call to -waitForExpectationsWithTimeout:handler: times out or has
 * had all associated expectations fulfilled.
 *
 * @param error
 * If the wait timed out or a failure was raised while waiting, the error's code
 * will specify the type of failure. Otherwise error will be nil.
 */
typedef void (^XCWaitCompletionHandler)(NSError *error);

/*!
 * @method -waitForExpectationsWithTimeout:handler:
 *
 * @param timeout
 * The amount of time within which all expectations must be fulfilled.
 *
 * @param handlerOrNil
 * If provided, the handler will be invoked both on timeout or fulfillment of all
 * expectations. Timeout is always treated as a test failure.
 *
 * @discussion
 * -waitForExpectationsWithTimeout:handler: creates a point of synchronization in the flow of a
 * test. Only one -waitForExpectationsWithTimeout:handler: can be active at any given time, but
 * multiple discrete sequences of { expectations -> wait } can be chained together.
 *
 * -waitForExpectationsWithTimeout:handler: runs the run loop while handling events until all expectations
 * are fulfilled or the timeout is reached. Clients should not manipulate the run
 * loop while using this API.
 */
- (void)waitForExpectationsWithTimeout:(NSTimeInterval)timeout handler:(XCWaitCompletionHandler)handlerOrNil;

#if XCTestExpectation_OHRetroCompat_BETTER_FAILURE_LOCATIONS
- (XCTestExpectation *)__file:(const char*)_ line:(NSUInteger)_ expectationWithDescription:(NSString *)description;
- (void)__file:(const char*)_ line:(NSUInteger)_ waitForExpectationsWithTimeout:(NSTimeInterval)timeout handler:(XCWaitCompletionHandler)handlerOrNil;
#define expectationWithDescription __file:__FILE__ line:__LINE__ expectationWithDescription
#define waitForExpectationsWithTimeout __file:__FILE__ line:__LINE__ waitForExpectationsWithTimeout
#endif

@end

#define XCTestCase XCTestCaseAsync

#endif
