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
    [self _test_NSURLSession:session jsonForStub:json instance:nil completion:completion];
}

- (void)_test_NSURLSession:(NSURLSession*)session
               jsonForStub:(id)json
                  instance:(OHHTTPStubs* _Nullable)instance
                completion:(void(^)(NSError* errorResponse,id jsonResponse))completion
{
    if ([NSURLSession class])
    {
        static const NSTimeInterval kRequestTime = 0.0;
        static const NSTimeInterval kResponseTime = 0.2;
        
        OHHTTPStubsTestBlock test = ^BOOL(NSURLRequest *request) {
            return YES;
        };
        OHHTTPStubsResponseBlock response = ^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithJSONObject:json statusCode:200 headers:nil]
                    requestTime:kRequestTime responseTime:kResponseTime];
        };
        
        if (instance) {
            [instance stubRequestsPassingTest:test withStubResponse:response];
        } else {
            [OHHTTPStubs stubRequestsPassingTest:test withStubResponse:response];
        }
        
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
                        jsonForStub:(id)json
                         completion:(void(^)(NSError* errorResponse, NSHTTPURLResponse *response, id jsonResponse))completion
{
    [self _test_redirect_NSURLSession:session jsonForStub:json instance:nil completion:completion];
}

- (void)_test_redirect_NSURLSession:(NSURLSession*)session
                        jsonForStub:(id)json
                           instance:(OHHTTPStubs* _Nullable)instance
                         completion:(void(^)(NSError* errorResponse, NSHTTPURLResponse *response, id jsonResponse))completion
{
    if ([NSURLSession class])
    {
        static const NSTimeInterval kRequestTime = 0.2;
        static const NSTimeInterval kResponseTime = 0.2;
        
        OHHTTPStubsTestBlock test1 = ^BOOL(NSURLRequest *request) {
            return [[[request URL] path] isEqualToString:@""];
        };
        OHHTTPStubsResponseBlock response1 = ^OHHTTPStubsResponse *(NSURLRequest *request) {
            NSDictionary *headers = @{ @"Location": @"foo://unknownhost:666/elsewhere" };
            return [[OHHTTPStubsResponse responseWithData:[[NSData alloc] init] statusCode:301 headers:headers]
                    requestTime:kRequestTime responseTime:kResponseTime];
        };
        
        OHHTTPStubsTestBlock test2 = ^BOOL(NSURLRequest *request) {
            return [[[request URL] path] isEqualToString:@"/elsewhere"];
        };
        OHHTTPStubsResponseBlock response2 = ^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithJSONObject:json statusCode:200 headers:nil]
                    requestTime:kRequestTime responseTime:kResponseTime];
        };
        
        if (instance) {
            [instance stubRequestsPassingTest:test1 withStubResponse:response1];
            [instance stubRequestsPassingTest:test2 withStubResponse:response2];
        } else {
            [OHHTTPStubs stubRequestsPassingTest:test1 withStubResponse:response1];
            [OHHTTPStubs stubRequestsPassingTest:test2 withStubResponse:response2];
        }

        XCTestExpectation* expectation = [self expectationWithDescription:@"NSURLSessionDataTask completed"];

        __block __strong NSHTTPURLResponse *redirectResponse = nil;
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
                                               NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
                                               if ([HTTPResponse statusCode] >= 300 && [HTTPResponse statusCode] < 400) {
                                                   redirectResponse = HTTPResponse;
                                               } else {
                                                   NSError *jsonError = nil;
                                                   NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                   XCTAssertNil(jsonError, @"Unexpected error deserializing JSON response");
                                                   dataResponse = jsonObject;
                                               }
                                           }
                                           [expectation fulfill];
                                       }];

        NSDate *startTime = [NSDate date];
        [task resume];

        [self waitForExpectationsWithTimeout:(kRequestTime+kResponseTime)*2+0.1 handler:^(NSError * _Nullable error) {
            NSDate *finishTime = [NSDate date];
            NSTimeInterval totalResponseTime = [finishTime timeIntervalSinceDate:startTime];
            if (redirectResponse) {
                XCTAssertGreaterThanOrEqual(totalResponseTime, (kRequestTime + kResponseTime), @"Redirect did not honor request/response time");
            }
            else if (dataResponse) {
                // NSURLSession does not wait for the 3xx response to stream before starting the second request.
                // Thus, the 3xx and final responses will stream in parallel.
                XCTAssertGreaterThanOrEqual(totalResponseTime, ((2 * kRequestTime) + kResponseTime), @"Redirect or final request did not honor request/response time");
            }
            completion(errorResponse, redirectResponse, dataResponse);
        }];
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

        [self _test_redirect_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];
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

        [self _test_redirect_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];
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

        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_redirect_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNotNil(redirectResponse, @"Redirect response should have been received");
            XCTAssertEqual(301, [redirectResponse statusCode], @"Expected 301 redirect");
            XCTAssertNil(jsonResponse, @"Unexpected data received");
        }];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionDefaultConfig_customInstance
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        [OHHTTPStubs setEnabled:NO forSessionConfiguration:config];
        
        OHHTTPStubs* custom = [OHHTTPStubs new];
        [custom setEnabled:YES forSessionConfiguration:config];
        
        NSDictionary* defaultJSON = @{@"Failure": @"Yes"};
        NSDictionary* customJSON = @{@"Success": @"Yes"};
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest* request) {
            return YES;
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [OHHTTPStubsResponse responseWithJSONObject:defaultJSON
                                                    statusCode:200
                                                       headers:nil];
        }];
        
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        [self _test_NSURLSession:session jsonForStub:customJSON instance:custom completion:^(NSError *errorResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertEqualObjects(jsonResponse, customJSON, @"Unexpected data received");
        }];
        
        [self _test_redirect_NSURLSession:session jsonForStub:customJSON instance:custom completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertEqualObjects(jsonResponse, customJSON, @"Unexpected data received");
        }];
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

        [self _test_redirect_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionEphemeralConfig_Disabled
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        BOOL wasEnabled = [OHHTTPStubs isEnabled];
        XCTAssert(wasEnabled, @"Stubs are expected to be on by default");
        [OHHTTPStubs setEnabled:NO];
        XCTAssert(![OHHTTPStubs isEnabled], @"isEnabled should report NO after turning off");
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        [OHHTTPStubs setEnabled:YES];
        XCTAssert([OHHTTPStubs isEnabled], @"isEnabled should report YES after turning on");
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            // Stubs were disable for this session, so we should get an error instead of the stubs data
            XCTAssertNotNil(errorResponse, @"Expected error but none found");
            XCTAssertNil(jsonResponse, @"Data should not have been received as stubs should be disabled");
        }];
        
        [self _test_redirect_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            // Stubs were disable for this session, so we should get an error instead of the stubs data
            XCTAssertNotNil(errorResponse, @"Expected error but none found");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received as stubs should be disabled");
            XCTAssertNil(jsonResponse, @"Data should not have been received as stubs should be disabled");
        }];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionEphemeralConfig_DisabledForSession
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

        [self _test_redirect_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            // Stubs were disable for this session, so we should get an error instead of the stubs data
            XCTAssertNotNil(errorResponse, @"Expected error but none found");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received as stubs should be disabled");
            XCTAssertNil(jsonResponse, @"Data should not have been received as stubs should be disabled");
        }];
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
