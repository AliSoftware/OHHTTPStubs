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
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "AFHTTPRequestOperation.h"

static const NSTimeInterval kResponseTimeTolerence = 1.0;

@interface AFNetworkingTests : XCTestCase @end

@implementation AFNetworkingTests

-(void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
}

-(void)test_AFHTTPRequestOperation_success
{
    static const NSTimeInterval kRequestTime = 0.05;
    static const NSTimeInterval kResponseTime = 0.1;
    NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 headers:nil]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"AFHTTPRequestOperation request finished"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    AFHTTPRequestOperation* op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    [op setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    __block __strong id response = nil;
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        response = responseObject; // keep strong reference
        [expectation fulfill];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Unexpected network failure");
        [expectation fulfill];
    }];
    [op start];
    
    [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+kResponseTimeTolerence handler:nil];
    
    XCTAssertEqualObjects(response, expectedResponse, @"Unexpected data received");
}

-(void)test_AFHTTPRequestOperation_multiple_choices
{
    static const NSTimeInterval kRequestTime = 0.05;
    static const NSTimeInterval kResponseTime = 0.1;
    NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:300 headers:@{@"Location":@"http://www.iana.org/domains/another/example"}]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"AFHTTPRequestOperation request finished"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    AFHTTPRequestOperation* op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    AFHTTPResponseSerializer* serializer = [AFHTTPResponseSerializer serializer];
    [serializer  setAcceptableStatusCodes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 101)]];
    [op setResponseSerializer:serializer];

    __block __strong id response = nil;
    [op setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if (redirectResponse == nil) {
            return request;
        }
        XCTFail(@"Unexpected redirect");
        return nil;
    }];
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        response = responseObject; // keep strong reference
        [expectation fulfill];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Unexpected network failure");
        [expectation fulfill];
    }];
    [op start];
    
    [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+kResponseTimeTolerence handler:nil];
    
    XCTAssertEqualObjects(response, expectedResponse, @"Unexpected data received");
}

-(void)test_AFHTTPRequestOperation_redirect
{
    static const NSTimeInterval kRequestTime = 0.05;
    static const NSTimeInterval kResponseTime = 0.1;
    
    NSURL* redirectURL = [NSURL URLWithString:@"http://www.iana.org/domains/another/example"];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithData:[NSData data] statusCode:311 headers:@{@"Location":redirectURL.absoluteString}]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"AFHTTPRequestOperation request finished"];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    AFHTTPRequestOperation* op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    [op setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    __block __strong NSURL* url = nil;
    [op setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if (redirectResponse == nil) {
            return request;
        }
        url = request.URL;
        [expectation fulfill];
        return nil;
    }];
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        XCTFail(@"Unexpected response");
        [expectation fulfill];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        XCTFail(@"Unexpected network failure");
        [expectation fulfill];
    }];
    [op start];
    
    [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+kResponseTimeTolerence handler:nil];
    
    XCTAssertEqualObjects(url, redirectURL, @"Unexpected data received");
}

@end



#pragma mark - NSURLSession / AFHTTPURLSession support

// Compile this only if SDK version (…MAX_ALLOWED) is iOS7+/10.9+ because NSURLSession is a class only known starting these SDKs
// (this code won't compile if we use an eariler SDKs, like when building with Xcode4)
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) \
 || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)

#import "AFHTTPSessionManager.h"

@interface AFNetworkingTests (NSURLSession) @end
@implementation AFNetworkingTests (NSURLSession)

- (void)test_AFHTTPURLSessionCustom
{
    if ([NSURLSession class] && [NSURLSessionConfiguration class])
    {
        static const NSTimeInterval kRequestTime = 0.1;
        static const NSTimeInterval kResponseTime = 0.2;
        NSDictionary *expectedResponseDict = @{@"Success" : @"Yes"};
        
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.scheme isEqualToString:@"stubs"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithJSONObject:expectedResponseDict statusCode:200 headers:nil]
                    requestTime:kRequestTime responseTime:kResponseTime];
        }];
        
        XCTestExpectation* expectation = [self expectationWithDescription:@"AFHTTPSessionManager request finished"];
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURL* baseURL = [NSURL URLWithString:@"stubs://stubs/"];
        AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL
                                                                        sessionConfiguration:sessionConfig];
        
        __block __strong id response = nil;
        [sessionManager GET:@"foo"
                 parameters:nil
                    success:^(NSURLSessionDataTask *task, id responseObject) {
                        response = responseObject; // keep strong reference
                        [expectation fulfill];
                    }
                    failure:^(NSURLSessionDataTask *task, NSError *error) {
                        XCTFail(@"Unexpected network failure");
                        [expectation fulfill];
                    }];
        
        [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+kResponseTimeTolerence handler:nil];
        
        XCTAssertEqualObjects(response, expectedResponseDict, @"Unexpected data received");
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

@end

#else
#warning Unit Tests using NSURLSession were not compiled nor executed, because NSURLSession is only available since iOS7/OSX10.9 SDK. \
-------- Compile using iOS7 or OSX10.9 SDK then launch the tests on the iOS7 simulator or an OSX10.9 target for them to be executed.
#endif
