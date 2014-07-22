//
//  TimingTests.m
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 01/09/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import "AsyncSenTestCase.h"
#import "OHHTTPStubs.h"

@interface TimingTests : AsyncSenTestCase
{
    NSMutableData* _data;
    NSError* _error;
    
//    NSDate* _didReceiveResponseTS;
    NSDate* _didFinishLoadingTS;
}
@end

@implementation TimingTests

-(void)setUp
{
    _data = [NSMutableData new];
    _error = nil;
//    _didReceiveResponseTS = nil;
    _didFinishLoadingTS = nil;
    [OHHTTPStubs removeAllStubs];
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_data setLength:0U];
    // NOTE: This timing info is not reliable as Cocoa always calls the connection:didReceiveResponse: delegate method just before
    // calling the first "connection:didReceiveData:", even if the [id<NSURLProtocolClient> URLProtocol:didReceiveResponse:…] method was called way before.
//    _didReceiveResponseTS = [NSDate date];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _error = error; // keep strong reference
    _didFinishLoadingTS = [NSDate date];
    [self notifyAsyncOperationDone];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _didFinishLoadingTS = [NSDate date];
    [self notifyAsyncOperationDone];
}


///////////////////////////////////////////////////////////////////////////////////////

static NSTimeInterval const kResponseTimeTolerence = 0.3;
static NSTimeInterval const kSecurityTimeout = 5.0;

-(void)_testWithData:(NSData*)stubData requestTime:(NSTimeInterval)requestTime responseTime:(NSTimeInterval)responseTime
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithData:stubData
                                           statusCode:200
                                              headers:nil]
                requestTime:requestTime responseTime:responseTime];
    }];
    
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startTS = [NSDate date];
    
    [NSURLConnection connectionWithRequest:req delegate:self];
    
    [self waitForAsyncOperationWithTimeout:requestTime+responseTime+kResponseTimeTolerence+kSecurityTimeout];

    STAssertEqualObjects(_data, stubData, @"Invalid data response");

//    STAssertEqualsWithAccuracy([_didReceiveResponseTS timeIntervalSinceDate:startTS], requestTime,
//                               kResponseTimeTolerence, @"Invalid request time");
    STAssertEqualsWithAccuracy([_didFinishLoadingTS timeIntervalSinceDate:startTS], requestTime + responseTime,
                               kResponseTimeTolerence, @"Invalid response time");
    
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
