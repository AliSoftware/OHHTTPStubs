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


#import <XCTest/XCTest.h>

#if OHHTTPSTUBS_USE_STATIC_LIBRARY
#import "OHHTTPStubs.h"
#else
@import OHHTTPStubs;
#endif

@interface WithContentsOfURLTests : XCTestCase @end

static const NSTimeInterval kResponseTimeTolerence = 0.2;

@implementation WithContentsOfURLTests

-(void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
}

static const NSTimeInterval kRequestTime = 0.1;
static const NSTimeInterval kResponseTime = 0.5;

///////////////////////////////////////////////////////////////////////////////////
#pragma mark [NSString stringWithContentsOfURL:encoding:error:]
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSString_stringWithContentsOfURL_mainQueue
{
    NSString* testString = NSStringFromSelector(_cmd);
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithData:[testString dataUsingEncoding:NSUTF8StringEncoding]
                                           statusCode:200
                                              headers:nil]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];
    
    NSDate* startDate = [NSDate date];
    
    NSString* string = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]
                                            encoding:NSUTF8StringEncoding
                                               error:NULL];
    
    XCTAssertEqualObjects(string, testString, @"Invalid returned string");
    XCTAssertEqualWithAccuracy(-[startDate timeIntervalSinceNow], kResponseTime+kRequestTime, kResponseTimeTolerence, @"Invalid response time");
}

-(void)test_NSString_stringWithContentsOfURL_parallelQueue
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Synchronous download finished"];
    [[NSOperationQueue new] addOperationWithBlock:^{
        [self test_NSString_stringWithContentsOfURL_mainQueue];
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+kResponseTimeTolerence handler:nil];
}

///////////////////////////////////////////////////////////////////////////////////
#pragma mark [NSData dataWithContentsOfURL:]
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSData_dataWithContentsOfURL_mainQueue
{
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithData:testData
                                           statusCode:200
                                              headers:nil]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];
    
    NSDate* startDate = [NSDate date];
    
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    XCTAssertEqualObjects(data, testData, @"Invalid returned string");
    XCTAssertEqualWithAccuracy(-[startDate timeIntervalSinceNow], kRequestTime+kResponseTime, kResponseTimeTolerence, @"Invalid response time");
}

-(void)test_NSData_dataWithContentsOfURL_parallelQueue
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"Synchronous download finished"];
    [[NSOperationQueue new] addOperationWithBlock:^{
        [self test_NSData_dataWithContentsOfURL_mainQueue];
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+kResponseTimeTolerence handler:nil];
}

@end
