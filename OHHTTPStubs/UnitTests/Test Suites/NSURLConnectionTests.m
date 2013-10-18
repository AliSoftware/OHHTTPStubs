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
#import "OHHTTPStubs.h"

@interface NSURLConnectionTests : AsyncSenTestCase @end

static const NSTimeInterval kResponseTimeTolerence = 0.3;

@implementation NSURLConnectionTests

-(void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
}

static const NSTimeInterval kRequestTime = 0.1;
static const NSTimeInterval kResponseTime = 0.5;

///////////////////////////////////////////////////////////////////////////////////
#pragma mark [NSURLConnection sendSynchronousRequest:returningResponse:error:]
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLConnection_sendSyncronousRequest_mainQueue
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
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startDate = [NSDate date];
    
    NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:NULL error:NULL];
    
    STAssertEqualObjects(data, testData, @"Invalid data response");
    STAssertEqualsWithAccuracy(-[startDate timeIntervalSinceNow], kRequestTime+kResponseTime, kResponseTimeTolerence, @"Invalid response time");
}

-(void)test_NSURLConnection_sendSyncronousRequest_parallelQueue
{
    [[NSOperationQueue new] addOperationWithBlock:^{
        [self test_NSURLConnection_sendSyncronousRequest_mainQueue];
        [self notifyAsyncOperationDone];
    }];
    [self waitForAsyncOperationWithTimeout:kRequestTime+kResponseTime+kResponseTimeTolerence];
}

///////////////////////////////////////////////////////////////////////////////////
#pragma mark Single [NSURLConnection sendAsynchronousRequest:queue:completionHandler:]
///////////////////////////////////////////////////////////////////////////////////

-(void)_test_NSURLConnection_sendAsyncronousRequest_onOperationQueue:(NSOperationQueue*)queue
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
    
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startDate = [NSDate date];
    
    [NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         STAssertEqualObjects(data, testData, @"Invalid data response");
         STAssertEqualsWithAccuracy(-[startDate timeIntervalSinceNow], kRequestTime+kResponseTime, kResponseTimeTolerence, @"Invalid response time");
         
         [self notifyAsyncOperationDone];
     }];
    
    [self waitForAsyncOperationWithTimeout:kRequestTime+kResponseTime+kResponseTimeTolerence];
}


-(void)test_NSURLConnection_sendAsyncronousRequest_mainQueue
{
    [self _test_NSURLConnection_sendAsyncronousRequest_onOperationQueue:NSOperationQueue.mainQueue];
}


-(void)test_NSURLConnection_sendAsyncronousRequest_parallelQueue
{
    [self _test_NSURLConnection_sendAsyncronousRequest_onOperationQueue:[NSOperationQueue new]];
}


///////////////////////////////////////////////////////////////////////////////////
#pragma mark Multiple Parallel [NSURLConnection sendAsynchronousRequest:queue:completionHandler:]
///////////////////////////////////////////////////////////////////////////////////

-(void)_test_NSURLConnection_sendMultipleAsyncronousRequestsOnOperationQueue:(NSOperationQueue*)queue
{
    
    NSData* (^dataForRequest)(NSURLRequest*) = ^(NSURLRequest* req) {
        return [[NSString stringWithFormat:@"<Response for URL %@>",req.URL.absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
    };
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSData* retData = dataForRequest(request);
        NSTimeInterval responseTime = [request.URL.lastPathComponent doubleValue];
        return [[OHHTTPStubsResponse responseWithData:retData
                                           statusCode:200
                                              headers:nil]
                requestTime:responseTime*.1 responseTime:responseTime];
    }];
    
    // Reusable code to send a request that will respond in the given response time
    void (^sendAsyncRequest)(NSTimeInterval) = ^(NSTimeInterval responseTime)
    {
        NSString* urlString = [NSString stringWithFormat:@"http://dummyrequest/concurrent/time/%f",responseTime];
        NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
//        [SenTestLog testLogWithFormat:@"== Sending request %@\n", req];
        NSDate* startDate = [NSDate date];
        [NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
         {
//             [SenTestLog testLogWithFormat:@"== Received response for request %@\n", req];
             STAssertEqualObjects(data, dataForRequest(req), @"Invalid data response");
             STAssertEqualsWithAccuracy(-[startDate timeIntervalSinceNow], (responseTime*.1)+responseTime, kResponseTimeTolerence, @"Invalid response time");
             
             [self notifyAsyncOperationDone];
         }];
    };

    static NSTimeInterval time3 = 1.5, time2 = 1.0, time1 = 0.5;
    sendAsyncRequest(time3); // send this one first, should receive last
    sendAsyncRequest(time2); // send this one next, shoud receive 2nd
    sendAsyncRequest(time1); // send this one last, should receive first

    [self waitForAsyncOperations:3 withTimeout:MAX(time1,MAX(time2,time3))+kResponseTimeTolerence];
}

-(void)test_NSURLConnection_sendMultipleAsyncronousRequests_mainQueue
{
    [self _test_NSURLConnection_sendMultipleAsyncronousRequestsOnOperationQueue:NSOperationQueue.mainQueue];
}

-(void)test_NSURLConnection_sendMultipleAsyncronousRequests_parallelQueue
{
    [self _test_NSURLConnection_sendMultipleAsyncronousRequestsOnOperationQueue:[NSOperationQueue new]];
}


@end
