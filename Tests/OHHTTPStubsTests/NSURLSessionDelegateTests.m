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

#import <XCTest/XCTest.h>

#if OHHTTPSTUBS_USE_STATIC_LIBRARY || SWIFT_PACKAGE
#import "HTTPStubs.h"
#else
@import OHHTTPStubs;
#endif

@interface NSURLSessionDelegateTests : XCTestCase <NSURLSessionTaskDelegate, NSURLSessionDataDelegate> @end

static const NSTimeInterval kResponseTimeMaxDelay = 2.5;

@implementation NSURLSessionDelegateTests
{
    NSMutableData* _data;
    NSError* _error;

    NSURL* _redirectRequestURL;
    NSInteger _redirectResponseStatusCode;

    XCTestExpectation* _connectionFinishedExpectation;
}

///////////////////////////////////////////////////////////////////////////////////
#pragma mark Global Setup + NSURLSessionDelegate implementation
///////////////////////////////////////////////////////////////////////////////////

-(void)setUp
{
    [super setUp];
    _data = [[NSMutableData alloc] init];
    [HTTPStubs removeAllStubs];
}

-(void)tearDown
{
    // in case the test timed out and finished before a running NSURLSessionTask ended,
    // we may continue receive delegate messages anyway if we forgot to cancel.
    // So avoid sending messages to deallocated object in this case by ensuring we reset it to nil
    _data = nil;
    _error = nil;
    _connectionFinishedExpectation = nil;
    [super tearDown];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                     willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                                     newRequest:(NSURLRequest *)request
                              completionHandler:(void (NS_SWIFT_SENDABLE ^)(NSURLRequest * _Nullable))completionHandler
{
    _redirectRequestURL = request.URL;
    if (response)
    {
        if ([response isKindOfClass:NSHTTPURLResponse.class])
        {
            _redirectResponseStatusCode = ((NSHTTPURLResponse *) response).statusCode;
        }
        else
        {
            _redirectResponseStatusCode = 0;
        }
    }
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (NS_SWIFT_SENDABLE ^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    _data.length = 0L;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    _error = error;
    [_connectionFinishedExpectation fulfill];
}

///////////////////////////////////////////////////////////////////////////////////
#pragma mark NSURLSession + Delegate
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLSessionDelegate_success
{
    static const NSTimeInterval kRequestTime = 0.1;
    static const NSTimeInterval kResponseTime = 0.5;
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];

    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithData:testData
                                           statusCode:200
                                              headers:nil]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];

    _connectionFinishedExpectation = [self expectationWithDescription:@"NSURLSession did finish (with error or success)"];

    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startDate = [NSDate date];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:req];
    [task resume];

    [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+kResponseTimeMaxDelay handler:nil];

    XCTAssertEqualObjects(_data, testData, @"Invalid data response");
    XCTAssertNil(_error, @"Received unexpected network error %@", _error);
    XCTAssertGreaterThan(-[startDate timeIntervalSinceNow], kRequestTime+kResponseTime, @"Invalid response time");

    // in case we timed out before the end of the request (test failed), cancel the request to avoid further delegate method calls
    [task cancel];
}

-(void)test_NSURLSessionDelegate_multiple_choices
{
    static const NSTimeInterval kRequestTime = 0.1;
    static const NSTimeInterval kResponseTime = 0.5;
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];

    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithData:testData
                                           statusCode:300
                                              headers:@{@"Location":@"http://www.iana.org/domains/another/example"}]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];

    _connectionFinishedExpectation = [self expectationWithDescription:@"NSURLSession did finish (with error or success)"];

    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startDate = [NSDate date];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:req];
    [task resume];

    [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+kResponseTimeMaxDelay handler:nil];

    XCTAssertEqualObjects(_data, testData, @"Invalid data response");
    XCTAssertNil(_error, @"Received unexpected network error %@", _error);
    XCTAssertGreaterThan(-[startDate timeIntervalSinceNow], kRequestTime+kResponseTime, @"Invalid response time");

    // in case we timed out before the end of the request (test failed), cancel the request to avoid further delegate method calls
    [task cancel];
}

-(void)test_NSURLSessionDelegate_error
{
    static const NSTimeInterval kResponseTime = 0.5;
    NSError* expectedError = [NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:nil];

    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        HTTPStubsResponse* resp = [HTTPStubsResponse responseWithError:expectedError];
        resp.responseTime = kResponseTime;
        return resp;
    }];

    _connectionFinishedExpectation = [self expectationWithDescription:@"NSURLSession did finish (with error or success)"];

    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startDate = [NSDate date];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:req];
    [task resume];

    [self waitForExpectationsWithTimeout:kResponseTime+kResponseTimeMaxDelay handler:nil];

    XCTAssertEqual(_data.length, (NSUInteger)0, @"Received unexpected network data %@", _data);
    XCTAssertEqualObjects(_error.domain, expectedError.domain, @"Invalid error response domain");
    XCTAssertEqual(_error.code, expectedError.code, @"Invalid error response code");
    XCTAssertGreaterThan(-[startDate timeIntervalSinceNow], kResponseTime, @"Invalid response time");

    // in case we timed out before the end of the request (test failed), cancel the request to avoid further delegate method calls
    [task cancel];
}


///////////////////////////////////////////////////////////////////////////////////
#pragma mark Cancelling requests
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLSession_cancel
{
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithData:[@"<this data should never have time to arrive>" dataUsingEncoding:NSUTF8StringEncoding]
                                           statusCode:500
                                              headers:nil]
                requestTime:0.0 responseTime:1.5];
    }];

    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:req];
    [task resume];

    XCTestExpectation* waitExpectation = [self expectationWithDescription:@"Waiting 2s, after cancelling in the middle"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [task cancel];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [waitExpectation fulfill];
        });
    });

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        // in case we timed out before the end of the request (test failed), cancel the request to avoid further delegate method calls
        [task cancel];
    }];

    XCTAssertEqual(_data.length, (NSUInteger)0, @"Received unexpected data but the request should have been cancelled");
    XCTAssertEqual(_error.domain, NSURLErrorDomain, @"Received unexpected network error but the request should have been cancelled");
    XCTAssertEqual(_error.code, NSURLErrorCancelled, @"Received unexpected network error but the request should have been cancelled");
}


///////////////////////////////////////////////////////////////////////////////////
#pragma mark Cancelling requests
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLSession_cookies
{
    NSString* const cookieName = @"SESSIONID";
    NSString* const cookieValue = [NSProcessInfo.processInfo globallyUniqueString];
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        NSString* cookie = [NSString stringWithFormat:@"%@=%@;", cookieName, cookieValue];
        NSDictionary* headers = @{@"Set-Cookie": cookie};
        return [[HTTPStubsResponse responseWithData:[@"Yummy cookies" dataUsingEncoding:NSUTF8StringEncoding]
                                           statusCode:200
                                              headers:headers]
                requestTime:0.0 responseTime:0.1];
    }];

    _connectionFinishedExpectation = [self expectationWithDescription:@"NSURLSession did finish (with error or success)"];

    // Set the cookie accept policy to accept all cookies from the main document domain
    // (especially in case the previous policy was "NSHTTPCookieAcceptPolicyNever")
    NSHTTPCookieStorage* cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage;
    NSHTTPCookieAcceptPolicy previousAcceptPolicy = cookieStorage.cookieAcceptPolicy; // keep it to restore later
    cookieStorage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain;

    // Send the request and wait for the response containing the Set-Cookie headers
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:req];
    [task resume];

    [self waitForExpectationsWithTimeout:kResponseTimeMaxDelay handler:^(NSError *error) {
        [task cancel]; // In case we timed out (test failed), cancel the request to avoid further delegate method calls
    }];

    /* Check that the cookie has been properly stored */
    NSArray* cookies = [cookieStorage cookiesForURL:req.URL];
    BOOL cookieFound = NO;
    for (NSHTTPCookie* cookie in cookies)
    {
        if ([cookie.name isEqualToString:cookieName])
        {
            cookieFound = YES;
            XCTAssertEqualObjects(cookie.value, cookieValue, @"The cookie does not have the expected value");
        }
    }
    XCTAssertTrue(cookieFound, @"The cookie was not stored as expected");


    // As a courtesy, restore previous policy before leaving
    cookieStorage.cookieAcceptPolicy = previousAcceptPolicy;
}


///////////////////////////////////////////////////////////////////////////////////
#pragma mark Redirected requests
///////////////////////////////////////////////////////////////////////////////////

- (void)test_NSURLSession_redirected
{
    static const NSTimeInterval kRequestTime = 0.1;
    static const NSTimeInterval kResponseTime = 0.5;
    NSData* redirectData = [[NSString stringWithFormat:@"%@ - redirect", NSStringFromSelector(_cmd)] dataUsingEncoding:NSUTF8StringEncoding];
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    NSURL* redirectURL = [NSURL URLWithString:@"http://www.yahoo.com/"];
    NSString* redirectCookieName = @"yahooCookie";
    NSString* redirectCookieValue = [NSProcessInfo.processInfo globallyUniqueString];

    // Set the cookie accept policy to accept all cookies from the main document domain
    // (especially in case the previous policy was "NSHTTPCookieAcceptPolicyNever")
    NSHTTPCookieStorage* cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage;
    NSHTTPCookieAcceptPolicy previousAcceptPolicy = cookieStorage.cookieAcceptPolicy; // keep it to restore later
    cookieStorage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain;

    NSString* endCookieName = @"googleCookie";
    NSString* endCookieValue = [NSProcessInfo.processInfo globallyUniqueString];
    NSURL *endURL = [NSURL URLWithString:@"http://www.google.com/"];

    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        if ([request.URL isEqual:redirectURL]) {
            NSString* redirectCookie = [NSString stringWithFormat:@"%@=%@;", redirectCookieName, redirectCookieValue];
            NSDictionary* headers = @{ @"Location": endURL.absoluteString,
                                       @"Set-Cookie": redirectCookie };
            return [[HTTPStubsResponse responseWithData:redirectData
                                               statusCode:311 // any 300-level request will do
                                                  headers:headers]
                    requestTime:kRequestTime responseTime:kResponseTime];
        } else {
            NSString* endCookie = [NSString stringWithFormat:@"%@=%@;", endCookieName, endCookieValue];
            NSDictionary* headers = @{ @"Set-Cookie": endCookie };
            return [[HTTPStubsResponse responseWithData:testData
                                               statusCode:200
                                                  headers:headers]
                    requestTime:kRequestTime responseTime:kResponseTime];
        }
    }];

    _connectionFinishedExpectation = [self expectationWithDescription:@"NSURLSession did finish (with error or success)"];

    NSURLRequest* req = [NSURLRequest requestWithURL:redirectURL];
    NSDate* startDate = [NSDate date];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:req];
    [task resume];

    [self waitForExpectationsWithTimeout:2 * (kRequestTime+kResponseTime+kResponseTimeMaxDelay) handler:^(NSError *error) {
        // in case we timed out before the end of the request (test failed), cancel the request to avoid further delegate method calls
        [task cancel];
    }];

    XCTAssertEqualObjects(_redirectRequestURL, endURL, @"Invalid redirect request URL");
    XCTAssertEqual(_redirectResponseStatusCode, (NSInteger)311, @"Invalid redirect response status code");
    XCTAssertEqualObjects(_data, testData, @"Invalid data response");
    XCTAssertNil(_error, @"Received unexpected network error %@", _error);
    XCTAssertGreaterThan(-[startDate timeIntervalSinceNow], (2 * kRequestTime) + kResponseTime, @"Invalid response time");

    /* Check that the redirect cookie has been properly stored */
    NSArray* redirectCookies = [cookieStorage cookiesForURL:req.URL];
    BOOL redirectCookieFound = NO;
    for (NSHTTPCookie* cookie in redirectCookies)
    {
        if ([cookie.name isEqualToString:redirectCookieName])
        {
            redirectCookieFound = YES;
            XCTAssertEqualObjects(cookie.value, redirectCookieValue, @"The redirect cookie does not have the expected value");
        }
    }
    XCTAssertTrue(redirectCookieFound, @"The redirect cookie was not stored as expected");

    /* Check that the end cookie has been properly stored */
    NSArray* endCookies = [cookieStorage cookiesForURL:endURL];
    BOOL endCookieFound = NO;
    for (NSHTTPCookie* cookie in endCookies)
    {
        if ([cookie.name isEqualToString:endCookieName])
        {
            endCookieFound = YES;
            XCTAssertEqualObjects(cookie.value, endCookieValue, @"The end cookie does not have the expected value");
        }
    }
    XCTAssertTrue(endCookieFound, @"The end cookie was not stored as expected");


    // As a courtesy, restore previous policy before leaving
    cookieStorage.cookieAcceptPolicy = previousAcceptPolicy;
}

@end
