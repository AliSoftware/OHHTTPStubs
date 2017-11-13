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
// Compile this only if SDK version (…MAX_ALLOWED) is iOS7+/10.9+ because NSURLSession is a class only known starting these SDKs
// (this code won't compile if we use an eariler SDKs, like when building with Xcode4)
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) \
 || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090) \
 || (defined(__TV_OS_VERSION_MIN_REQUIRED) || defined(__WATCH_OS_VERSION_MIN_REQUIRED))

#import <XCTest/XCTest.h>

#if OHHTTPSTUBS_USE_STATIC_LIBRARY
#import "OHHTTPStubs.h"
#import "OHHTTPStubsResponse+JSON.h"
#import "NSURLRequest+HTTPBodyTesting.h"
#else
@import OHHTTPStubs;
#endif

@interface NSURLSessionTests : XCTestCase <NSURLSessionDataDelegate, NSURLSessionTaskDelegate> @end

@implementation NSURLSessionTests
{
    NSMutableData* _receivedData;
    XCTestExpectation* _taskDidCompleteExpectation;
    BOOL _shouldFollowRedirects;
}

- (void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
    _receivedData = nil;
    _shouldFollowRedirects = YES;
}

- (void)_test_NSURLSession:(NSURLSession*)session
               jsonForStub:(id)json
                completion:(void(^)(NSError* errorResponse,id jsonResponse))completion
{
    if ([NSURLSession class])
    {
        static const NSTimeInterval kRequestTime = 0.0;
        static const NSTimeInterval kResponseTime = 0.2;

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return YES;
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithJSONObject:json statusCode:200 headers:nil]
                    requestTime:kRequestTime responseTime:kResponseTime];
        }];

        XCTestExpectation* expectation = [self expectationWithDescription:@"NSURLSessionDataTask completed"];

        __block __strong id dataResponse = nil;
        __block __strong NSError* errorResponse = nil;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"foo://unknownhost:666"]];
        request.HTTPMethod = @"GET";
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        NSURLSessionDataTask *task =  [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            errorResponse = error;
            if (!error)
            {
                NSError *jsonError = nil;
                NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                XCTAssertNil(jsonError, @"Unexpected error deserializing JSON response");
                dataResponse = jsonObject;
            }
            [expectation fulfill];
        }];

        [task resume];

        [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+0.5 handler:^(NSError * _Nullable error) {
            completion(errorResponse, dataResponse);
        }];
    }
}

- (void)_test_redirect_NSURLSession:(NSURLSession*)session
                         httpMethod:(NSString *)requestHTTPMethod
                           jsonBody:(NSDictionary*)json
                             delays:(NSTimeInterval)delay
                 redirectStatusCode:(int)redirectStatusCode
                         completion:(void(^)(NSString* redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse))completion
{
    if ([NSURLSession class])
    {
        const NSTimeInterval requestTime = delay;
        const NSTimeInterval responseTime = delay;

        __block __strong NSString* capturedRedirectedRequestMethod = nil;
        __block __strong id capturedRedirectedRequestJSONBody = nil;
        __block __strong NSHTTPURLResponse* capturedRedirectHTTPResponse = nil;
        __block __strong id capturedResponseJSONBody = nil;
        __block __strong NSError* capturedResponseError = nil;

        NSData* requestBody = json ? [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL] : nil;

        // First request: just return a redirect response (3xx, empty body)
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [[[request URL] path] isEqualToString:@"/oldlocation"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *originalRequest) {
            NSDictionary *headers = @{ @"Location": @"foo://unknownhost:666/newlocation" };
            return [[OHHTTPStubsResponse responseWithData:[NSData new]
                                               statusCode:redirectStatusCode
                                                  headers:headers]
                    requestTime:requestTime responseTime:responseTime];
        }];

        // Second request = redirected location: capture method+body of the redirected request + return 200 with the finalJSONResponse
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [[[request URL] path] isEqualToString:@"/newlocation"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *redirectedRequest) {
            capturedRedirectedRequestMethod = redirectedRequest.HTTPMethod;
            if (redirectedRequest.OHHTTPStubs_HTTPBody) {
                capturedRedirectedRequestJSONBody = [NSJSONSerialization JSONObjectWithData:redirectedRequest.OHHTTPStubs_HTTPBody options:0 error:nil];
            } else {
                capturedRedirectedRequestJSONBody = nil;
            }
            return [[OHHTTPStubsResponse responseWithJSONObject:@{ @"RequestBody": json ?: [NSNull null] }
                                                     statusCode:200
                                                        headers:nil]
                    requestTime:requestTime responseTime:responseTime];
        }];

        XCTestExpectation* expectation = [self expectationWithDescription:@"NSURLSessionDataTask completed"];

        // Building the initial request.
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"foo://unknownhost:666/oldlocation"]];
        request.HTTPMethod = requestHTTPMethod;
        if (requestBody)
        {
            request.HTTPBody = requestBody;
            [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)(request.HTTPBody.length)] forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        }
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        NSDate *startTime = [NSDate date];
        NSURLSessionDataTask *task =
        [session dataTaskWithRequest:request
                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
         {
             if (!capturedResponseError) { capturedResponseError = error; }
             NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
             if ([HTTPResponse statusCode] >= 300 && [HTTPResponse statusCode] < 400) {
                 // Response for the redirect
                 NSTimeInterval redirectResponseTime = [[NSDate date] timeIntervalSinceDate:startTime];
                 XCTAssertGreaterThanOrEqual(redirectResponseTime, (requestTime + responseTime), @"Redirect did not honor request/response time");
                 capturedRedirectHTTPResponse = HTTPResponse;
             } else {
                 // Response for the final request
                 if (data) {
                     NSTimeInterval totalResponseTime = [[NSDate date] timeIntervalSinceDate:startTime];
                     XCTAssertGreaterThanOrEqual(totalResponseTime, ((2 * requestTime) + responseTime), @"Redirect or final request did not honor request/response time");
                 }

                 NSError *jsonError = nil;
                 NSDictionary *jsonObject = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError] : nil;
                 XCTAssertNil(jsonError, @"Unexpected error deserializing JSON response");
                 capturedResponseJSONBody = jsonObject;
             }
             [expectation fulfill];
         }];
        [task resume];

        [self waitForExpectationsWithTimeout:(requestTime+responseTime)*2+0.1 handler:nil];
        completion(capturedRedirectedRequestMethod, capturedRedirectedRequestJSONBody,
                   capturedRedirectHTTPResponse,
                   capturedResponseJSONBody, capturedResponseError);
    }
}

// The shared session use the same mechanism as NSURLConnection
// (based on protocols registered via +[NSURLProtocol registerClass:] and all)
// and no NSURLSessionConfiguration
- (void)test_SharedNSURLSession
{
    if ([NSURLSession class])
    {
        NSURLSession *session = [NSURLSession sharedSession];

        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];

        [self _test_redirect_NSURLSession:session httpMethod:@"GET" jsonBody:nil delays:0.1 redirectStatusCode:301
                               completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
        {
            XCTAssertEqualObjects(redirectedRequestMethod, @"GET", @"Expected redirected request to use GET method");
            XCTAssertNil(redirectedRequestJSONBody, @"Expected redirected request to have empty body");
            XCTAssertNil(redirectHTTPResponse, @"Redirect response should not have been captured by the task completion block");
            XCTAssertEqualObjects(finalJSONResponse, @{ @"RequestBody": [NSNull null] }, @"Unexpected data received");
            XCTAssertNil(errorResponse, @"Unexpected error");
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionDefaultConfig
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];

        [self _test_redirect_NSURLSession:session httpMethod:@"GET" jsonBody:nil delays:0.1 redirectStatusCode:301
                               completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
        {
            XCTAssertEqualObjects(redirectedRequestMethod, @"GET", @"Expected redirected request to use GET method");
            XCTAssertNil(redirectedRequestJSONBody, @"Expected redirected request to have empty body");
            XCTAssertNil(redirectHTTPResponse, @"Redirect response should not have been captured by the task completion block");
            XCTAssertEqualObjects(finalJSONResponse, @{ @"RequestBody": [NSNull null] }, @"Unexpected data received");
            XCTAssertNil(errorResponse, @"Unexpected error");
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionDefaultConfig_notFollowingRedirects
{
    _shouldFollowRedirects = NO;

    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        [self _test_redirect_NSURLSession:session httpMethod:@"GET" jsonBody:nil delays:0.1 redirectStatusCode:301
                               completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
        {
            XCTAssertNil(redirectedRequestMethod, @"Expected no redirected request to fire");
            XCTAssertNil(redirectedRequestJSONBody, @"Expected no redirected request to fire");
            XCTAssertNotNil(redirectHTTPResponse, @"Redirect response should have been received");
            XCTAssertNil(finalJSONResponse, @"Unexpected data received when no redirect");
            XCTAssertNil(errorResponse, @"Unexpected error");
        }];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

/**
 Verify that redirects of different methods and status codes are handled properly and
 that we retain the HTTP Method for specific HTTP status codes as well as the data payload.
 **/
- (void)test_NSURLSessionDefaultConfig_MethodAndDataRetentionOnRedirect
{
    _shouldFollowRedirects = YES;

    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        NSDictionary* json = @{ @"query": @"Hello World" };
        NSArray<NSString*>* allMethods = @[@"GET", @"HEAD", @"POST", @"PATCH", @"PUT"];

        /** 301: GET, HEAD, POST, PATCH, PUT **/
        for (NSString* method in allMethods) {
            [self _test_redirect_NSURLSession:session httpMethod:method jsonBody:json delays:0.0 redirectStatusCode:301
                                   completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
            {
                XCTAssertEqualObjects(redirectedRequestMethod, method, @"Expected the HTTP method to be unchanged after redirect");
                XCTAssertEqualObjects(redirectedRequestJSONBody, json, @"Expected redirected request to have the same body as the original request");
                XCTAssertNil(redirectHTTPResponse, @"Redirect response should not have been captured by the task completion block");
                XCTAssertEqualObjects(finalJSONResponse, @{ @"RequestBody": json }, @"Unexpected JSON response received");
                XCTAssertNil(errorResponse, @"Unexpected error");
            }];
        }

        /** 302: GET, HEAD, POST, PATCH, PUT **/
        for (NSString* method in allMethods) {
            [self _test_redirect_NSURLSession:session httpMethod:method jsonBody:json delays:0.0 redirectStatusCode:302
                                   completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
            {
                XCTAssertEqualObjects(redirectedRequestMethod, method,@"Expected the HTTP method to be unchanged after redirect");
                XCTAssertEqualObjects(redirectedRequestJSONBody, json, @"Expected redirected request to have the same body as the original request");
                XCTAssertNil(redirectHTTPResponse, @"Redirect response should not have been captured by the task completion block");
                XCTAssertEqualObjects(finalJSONResponse, @{ @"RequestBody": json }, @"Unexpected JSON response received");
                XCTAssertNil(errorResponse, @"Unexpected error");
            }];
        }

        /** 303: GET, HEAD, POST, PATCH, PUT **/
        for (NSString* method in allMethods) {
            [self _test_redirect_NSURLSession:session httpMethod:method jsonBody:json delays:0.0 redirectStatusCode:303
                                   completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
            {
                XCTAssertEqualObjects(redirectedRequestMethod, @"GET", @"Expected 303 redirected request HTTP method to be reset to GET");
                XCTAssertNil(redirectedRequestJSONBody, @"Expected 303 redirected request to have empty body");
                XCTAssertNil(redirectHTTPResponse, @"Redirect response should not have been captured by the task completion block");
                XCTAssertEqualObjects(finalJSONResponse, @{ @"RequestBody": json }, @"Unexpected JSON response received");
                XCTAssertNil(errorResponse, @"Unexpected error");
            }];
        }

        /** 307: GET, HEAD, POST, PATCH, PUT **/
        for (NSString* method in allMethods) {
            [self _test_redirect_NSURLSession:session httpMethod:method jsonBody:json delays:0.0 redirectStatusCode:307
                                   completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
            {
                XCTAssertEqualObjects(redirectedRequestMethod, method, @"Expected the HTTP method to be unchanged after redirect");
                XCTAssertEqualObjects(redirectedRequestJSONBody, json, @"Expected redirected request to have the same body as the original request");
                XCTAssertNil(redirectHTTPResponse, @"Redirect response should not have been captured by the task completion block");
                XCTAssertEqualObjects(finalJSONResponse, @{ @"RequestBody": json }, @"Unexpected JSON response received");
                XCTAssertNil(errorResponse, @"Unexpected error");
            }];
        }

        /** 308: GET, HEAD, POST, PATCH, PUT **/
        for (NSString* method in allMethods) {
            [self _test_redirect_NSURLSession:session httpMethod:method jsonBody:json delays:0.0 redirectStatusCode:308
                                   completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
            {
                XCTAssertEqualObjects(redirectedRequestMethod, method, @"Expected the HTTP method to be unchanged after redirect");
                XCTAssertEqualObjects(redirectedRequestJSONBody, json, @"Expected redirected request to have the same body as the original request");
                XCTAssertNil(redirectHTTPResponse, @"Redirect response should not have been captured by the task completion block");
                XCTAssertEqualObjects(finalJSONResponse, @{ @"RequestBody": json }, @"Unexpected JSON response received");
                XCTAssertNil(errorResponse, @"Unexpected error");
            }];
        }

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}
- (void)test_NSURLSessionEphemeralConfig
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];

        [self _test_redirect_NSURLSession:session httpMethod:@"GET" jsonBody:json delays:0.1 redirectStatusCode:301
                               completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *redirectHTTPResponse, id finalJSONResponse, NSError *errorResponse)
        {
            XCTAssertEqualObjects(redirectedRequestMethod, @"GET", @"Expected the HTTP method of redirected request to be GET");
            XCTAssertEqualObjects(redirectedRequestJSONBody, json, @"Expected redirected request to have the same body as the original request");
            XCTAssertNil(redirectHTTPResponse, @"Redirect response should not have been captured by the task completion block");
            XCTAssertEqualObjects(finalJSONResponse, @{ @"RequestBody": json }, @"Unexpected JSON response received");
            XCTAssertNil(errorResponse, @"Unexpected error");
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionDefaultConfig_Disabled
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        [OHHTTPStubs setEnabled:NO forSessionConfiguration:config]; // Disable stubs for this session
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            // Stubs were disable for this session, so we should get an error instead of the stubs data
            XCTAssertNotNil(errorResponse, @"Expected error but none found");
            XCTAssertNil(jsonResponse, @"Data should not have been received as stubs should be disabled");
        }];

        [self _test_redirect_NSURLSession:session httpMethod:@"GET" jsonBody:json delays:0.1 redirectStatusCode:301
                               completion:^(NSString *redirectedRequestMethod, id redirectedRequestJSONBody, NSHTTPURLResponse *finalHTTPResponse, id finalJSONResponse, NSError *errorResponse)
        {
            // Stubs were disabled for this session, so we should get an error instead of the stubs data
            XCTAssertNotNil(errorResponse, @"Expected error but none found");
            XCTAssertNil(finalHTTPResponse, @"Redirect response should not have been received as stubs should be disabled");
            XCTAssertNil(finalJSONResponse, @"Data should not have been received as stubs should be disabled");
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSession_DataTask_DelegateMethods
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.scheme isEqualToString:@"stub"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 headers:nil]
                    responseTime:0.5];
        }];

        _taskDidCompleteExpectation = [self expectationWithDescription:@"NSURLSessionDataTask completion delegate method called"];

        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        [[session dataTaskWithURL:[NSURL URLWithString:@"stub://foo"]] resume];

        [self waitForExpectationsWithTimeout:5 handler:nil];

        XCTAssertEqualObjects(_receivedData, expectedResponse, @"Unexpected response");

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionCustomHTTPBody
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
        NSString* expectedBodyString = @"body";

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            NSData* body = [request OHHTTPStubs_HTTPBody];
            return [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] isEqualToString:expectedBodyString];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 headers:nil]
                    responseTime:0.2];
        }];

        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        // setup for positive check
        _taskDidCompleteExpectation = [self expectationWithDescription:@"Complete successful body test"];

        NSMutableURLRequest* requestWithBody = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"stub://foo"]];
        requestWithBody.HTTPBody = [expectedBodyString dataUsingEncoding:NSUTF8StringEncoding];
        [[session dataTaskWithRequest:requestWithBody] resume];

        [self waitForExpectationsWithTimeout:5 handler:nil];
        XCTAssertEqualObjects(_receivedData, expectedResponse, @"Unexpected response: HTTP body check should be successful");

        // reset for negative check
        _taskDidCompleteExpectation = [self expectationWithDescription:@"Complete unsuccessful body test"];
        _receivedData = nil;

        requestWithBody.HTTPBody = [@"somethingElse" dataUsingEncoding:NSUTF8StringEncoding];
        [[session dataTaskWithRequest:requestWithBody] resume];

        [self waitForExpectationsWithTimeout:5 handler:nil];

        XCTAssertNil(_receivedData, @"Unexpected response: HTTP body check should not be successful");

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionNativeHTTPBody
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
        NSString* expectedBodyString = @"body";

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            NSData* body = [request HTTPBody]; // this is not expected to work correctly
            return [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] isEqualToString:expectedBodyString];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 headers:nil]
                    responseTime:0.2];
        }];

        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        _taskDidCompleteExpectation = [self expectationWithDescription:@"Complete body test"];

        NSMutableURLRequest* requestWithBody = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"stub://foo"]];
        requestWithBody.HTTPBody = [expectedBodyString dataUsingEncoding:NSUTF8StringEncoding];
        [[session dataTaskWithRequest:requestWithBody] resume];

        [self waitForExpectationsWithTimeout:5 handler:nil];
        XCTAssertNil(_receivedData, @"[request HTTPBody] is not expected to work. If this has been fixed, the OHHTTPStubs_HTTPBody can be removed.");

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

//---------------------------------------------------------------
#pragma mark - Delegate Methods

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    _receivedData = [NSMutableData new];
    completionHandler(NSURLSessionResponseAllow);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [_receivedData appendData:data];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [_taskDidCompleteExpectation fulfill];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    completionHandler(_shouldFollowRedirects ? request : nil);
}

@end

#else
#warning Unit Tests using NSURLSession were not compiled nor executed, because NSURLSession is only available since iOS7/OSX10.9 SDK. \
-------- Compile using iOS7 or OSX10.9 SDK then launch the tests on the iOS7 simulator or an OSX10.9 target for them to be executed.
#endif
