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

#import <Availability.h>
// tvOS & watchOS deprecate use of NSURLConnection but these tests are based on it
#if (!defined(__TV_OS_VERSION_MIN_REQUIRED) && !defined(__WATCH_OS_VERSION_MIN_REQUIRED))

#import <XCTest/XCTest.h>

#if OHHTTPSTUBS_USE_STATIC_LIBRARY
#import "OHHTTPStubs.h"
#import "OHPathHelpers.h"
#else
@import OHHTTPStubs;
#endif

static const NSTimeInterval kResponseTimeTolerence = 0.3;

@interface NilValuesTests : XCTestCase @end

@implementation NilValuesTests

-(void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
}

- (void)test_NilData
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        return [OHHTTPStubsResponse responseWithData:nil statusCode:400 headers:nil];
#pragma clang diagnostic pop
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Network request's completionHandler called"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         XCTAssertEqual(data.length, (NSUInteger)0, @"Data should be empty");
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:kResponseTimeTolerence handler:nil];
}

- (void)test_EmptyData
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithData:[NSData data] statusCode:400 headers:nil]
                requestTime:0.01 responseTime:0.01];
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Network request's completionHandler called"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         XCTAssertEqual(data.length, (NSUInteger)0, @"Data should be empty");
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:kResponseTimeTolerence handler:nil];
}

- (void)test_NilPath
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        return [[OHHTTPStubsResponse responseWithFileAtPath:nil statusCode:501 headers:nil]
                requestTime:0.01 responseTime:0.01];
#pragma clang diagnostic pop
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Network request's completionHandler called"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         XCTAssertEqual(data.length, (NSUInteger)0, @"Data should be empty");
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:kResponseTimeTolerence handler:nil];
}

- (void)test_NilPathWithURL
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        return [[OHHTTPStubsResponse responseWithFileURL:nil statusCode:501 headers:nil]
                requestTime:0.01 responseTime:0.01];
#pragma clang diagnostic pop
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Network request's completionHandler called"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         XCTAssertEqual(data.length, (NSUInteger)0, @"Data should be empty");
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:kResponseTimeTolerence handler:nil];
}

- (void)test_InvalidPath
{
    XCTAssertThrowsSpecificNamed([OHHTTPStubsResponse responseWithFileAtPath:@"foo/bar" statusCode:501 headers:nil]
                                 , NSException, NSInternalInconsistencyException, @"An exception should be thrown if a non-file URL is given");
}

- (void)test_InvalidPathWithURL
{
    NSURL *httpURL = [NSURL fileURLWithPath:@"foo/bar"];
    NSAssert(httpURL, @"If the URL is nil an empty response is sent instead of an exception being thrown");
    XCTAssertThrowsSpecificNamed([OHHTTPStubsResponse responseWithFileURL:httpURL statusCode:501 headers:nil]
                                 , NSException, NSInternalInconsistencyException, @"An exception should be thrown if a non-file URL is given");
}

- (void)test_NonFileURL
{
    NSURL *httpURL = [NSURL URLWithString:@"http://www.iana.org/domains/example/"];
    NSAssert(httpURL, @"If the URL is nil an empty response is sent instead of an exception being thrown");
    XCTAssertThrowsSpecificNamed([OHHTTPStubsResponse responseWithFileURL:httpURL statusCode:501 headers:nil]
                                 , NSException, NSInternalInconsistencyException, @"An exception should be thrown if a non-file URL is given");
}


- (void)test_EmptyFile
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* emptyFile = OHPathForFile(@"emptyfile.json", self.class);
        return [[OHHTTPStubsResponse responseWithFileAtPath:emptyFile statusCode:500 headers:nil]
                requestTime:0.01 responseTime:0.01];
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Network request's completionHandler called"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         XCTAssertEqual(data.length, (NSUInteger)0, @"Data should be empty");
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:kResponseTimeTolerence handler:nil];
}

- (void)test_EmptyFileWithURL
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSURL *fileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"emptyfile" withExtension:@"json"];
        return [[OHHTTPStubsResponse responseWithFileURL:fileURL statusCode:500 headers:nil]
                requestTime:0.01 responseTime:0.01];
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Network request's completionHandler called"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         XCTAssertEqual(data.length, (NSUInteger)0, @"Data should be empty");
         
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:kResponseTimeTolerence handler:nil];
}

- (void)_test_NilURLAndCookieHandlingEnabled:(BOOL)handleCookiesEnabled
{
    NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:expectedResponse
                                          statusCode:200
                                             headers:nil];
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"Network request's completionHandler called"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:nil];
#pragma clang diagnostic pop
    req.HTTPShouldHandleCookies = handleCookiesEnabled;
    
    __block NSData* response = nil;
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         response = data;
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:kResponseTimeTolerence handler:nil];
    
    XCTAssertEqualObjects(response, expectedResponse, @"Unexpected data received");
}

- (void)test_NilURLAndCookieHandlingEnabled
{
    [self _test_NilURLAndCookieHandlingEnabled:YES];
}

- (void)test_NilURLAndCookieHandlingDisabled
{
    [self _test_NilURLAndCookieHandlingEnabled:NO];
}

@end

#endif
