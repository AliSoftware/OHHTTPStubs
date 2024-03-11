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

#if OHHTTPSTUBS_SKIP_TIMING_TESTS
#warning Timing Tests will be skipped for this run.
#else

#import <Availability.h>

#import <XCTest/XCTest.h>

#if OHHTTPSTUBS_USE_STATIC_LIBRARY || SWIFT_PACKAGE
#import "HTTPStubs.h"
#else
@import OHHTTPStubs;
#endif

@interface TimingTests : XCTestCase <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
{
    NSMutableData* _data;
    NSError* _error;
    XCTestExpectation* _connectionFinishedExpectation;

//    NSDate* _didReceiveResponseTS;
    NSDate* _didFinishLoadingTS;
}
@end

@implementation TimingTests

-(void)setUp
{
    [super setUp];

    _data = [NSMutableData new];
    _error = nil;
//    _didReceiveResponseTS = nil;
    _didFinishLoadingTS = nil;
    [HTTPStubs removeAllStubs];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (NS_SWIFT_SENDABLE ^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    _data.length = 0L;
    // NOTE: This timing info is not reliable as Cocoa always calls the connection:didReceiveResponse: delegate method just before
    // calling the first "…didReceiveData:", even if the [id<NSURLProtocolClient> URLProtocol:didReceiveResponse:…] method
    // was called way before. So we are not testing this
//    _didReceiveResponseTS = [NSDate date];

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
    _didFinishLoadingTS = [NSDate date];
    [_connectionFinishedExpectation fulfill];
}

///////////////////////////////////////////////////////////////////////////////////////

static NSTimeInterval const kResponseTimeMaxDelay = 2.5;
static NSTimeInterval const kSecurityTimeout = 5.0;

-(void)_testWithData:(NSData*)stubData requestTime:(NSTimeInterval)requestTime responseTime:(NSTimeInterval)responseTime
{
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithData:stubData
                                           statusCode:200
                                              headers:nil]
                requestTime:requestTime responseTime:responseTime];
    }];

    _connectionFinishedExpectation = [self expectationWithDescription:@"NSURLSession did finish (with error or success)"];

    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startTS = [NSDate date];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:req];
    [task resume];

    [self waitForExpectationsWithTimeout:requestTime+responseTime+kResponseTimeMaxDelay+kSecurityTimeout handler:nil];

    XCTAssertEqualObjects(_data, stubData, @"Invalid data response");

    XCTAssertGreaterThan([_didFinishLoadingTS timeIntervalSinceDate:startTS], requestTime + responseTime, @"Invalid response time");

    [NSThread sleepForTimeInterval:0.01]; // Time for the test to wrap it all (otherwise we may have "Test did not finish" warning)
}






-(void)test_RequestTime0_ResponseTime0
{
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    [self _testWithData:testData requestTime:0 responseTime:0];
}

-(void)test_SmallDataLargeTime_CumulativeAlgorithm
{
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    // 21 bytes in 23/4 of a second = 0.913042 byte per slot: we need to check that the cumulative algorithm works
    [self _testWithData:testData requestTime:0 responseTime:5.75];
}

-(void)test_RequestTime1_ResponseTime0
{
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    [self _testWithData:testData requestTime:1 responseTime:0];
}

-(void)test_LongData_RequestTime1_ResponseTime5
{
    static NSUInteger const kDataLength = 1024;
    NSMutableData* testData = [NSMutableData dataWithCapacity:kDataLength];
    NSData* chunk = [[NSProcessInfo.processInfo globallyUniqueString] dataUsingEncoding:NSUTF8StringEncoding];
    while(testData.length<kDataLength)
    {
        [testData appendData:chunk];
    }
    [self _testWithData:testData requestTime:1 responseTime:5];
}

-(void)test_VeryLongData_RequestTime1_ResponseTime0
{
    static NSUInteger const kDataLength = 609792;
    NSMutableData* testData = [NSMutableData dataWithCapacity:kDataLength];
    NSData* chunk = [[NSProcessInfo.processInfo globallyUniqueString] dataUsingEncoding:NSUTF8StringEncoding];
    while(testData.length<kDataLength)
    {
        [testData appendData:chunk];
    }
    [self _testWithData:testData requestTime:1 responseTime:0];
}

@end

#endif
