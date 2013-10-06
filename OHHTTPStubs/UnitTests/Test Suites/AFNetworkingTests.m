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


#import "AsyncSenTestCase.h"
#import "AFHTTPRequestOperation.h"
#import "AFHTTPSessionManager.h"
#import "OHHTTPStubs.h"
#import "OHHTTPStubsResponse+JSON.h"

@interface AFNetworkingTests : AsyncSenTestCase @end

@implementation AFNetworkingTests

-(void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
}

-(void)test_AFHTTPRequestOperation
{
    static const NSTimeInterval kRequestTime = 1.0;
    static const NSTimeInterval kResponseTime = 1.0;
    NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 headers:nil]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    AFHTTPRequestOperation* op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    [op setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    __block __strong id response = nil;
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        response = responseObject; // keep strong reference
        [self notifyAsyncOperationDone];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        STFail(@"Unexpected network failure");
        [self notifyAsyncOperationDone];
    }];
    [op start];
    
    [self waitForAsyncOperationWithTimeout:kRequestTime+kResponseTime+0.5];
    
    STAssertEqualObjects(response, expectedResponse, @"Unexpected data received");
}

// Note: because AFNetworking conditionally compiles AFHTTPSessionManager only when the deployment target
// is iOS 7+, these tests will only be run when the tests are built for deployment on iOS 7+.
// Otherwise, compilation will fail.
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000)

- (void)test_AFHTTPURLSSessionCustom
{
    // For AFNetworking, this only works if you create a session with a custom configuration.
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil sessionConfiguration:sessionConfig];
    
    static const NSTimeInterval kRequestTime = 1.0;
    static const NSTimeInterval kResponseTime = 1.0;
    NSDictionary *expectedResponseDict = @{@"Success" : @"Yes"};
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithJSONObject:expectedResponseDict statusCode:200 headers:nil]
                requestTime:kRequestTime responseTime:kResponseTime];
    }];
    
    __block __strong id response = nil;
    [sessionManager GET:@"http://localhost:3333"
             parameters:nil
                success:^(NSURLSessionDataTask *task, id responseObject) {
                    response = responseObject; // keep strong reference
                    [self notifyAsyncOperationDone];
                }
                failure:^(NSURLSessionDataTask *task, NSError *error) {
                    STFail(@"Unexpected network failure");
                    [self notifyAsyncOperationDone];
                }];
    
    [self waitForAsyncOperationWithTimeout:kRequestTime+kResponseTime+0.5];
    
    STAssertEqualObjects(response, expectedResponseDict, @"Unexpected data received");
}
#endif

@end
