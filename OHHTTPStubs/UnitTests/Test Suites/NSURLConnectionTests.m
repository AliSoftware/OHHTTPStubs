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
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface NSURLConnectionTests : AsyncSenTestCase @end

static const NSTimeInterval kResponseTimeTolerence = 0.05;

@implementation NSURLConnectionTests


///////////////////////////////////////////////////////////////////////////////////
#pragma mark [NSURLConnection sendSynchronousRequest:returningResponse:error:]
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLConnection_sendSyncronousRequest_mainQueue
{
    static const NSTimeInterval kResponseTime = 2.0;
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {        
        return [OHHTTPStubsResponse responseWithData:testData
                                          statusCode:200
                                        responseTime:kResponseTime
                                             headers:nil];
    }];
        
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    NSDate* startDate = [NSDate date];
    
    NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:NULL error:NULL];
    
    STAssertEqualObjects(data, testData, @"Invalid data response");
    STAssertTrue( fabs(kResponseTime+[startDate timeIntervalSinceNow]) < kResponseTimeTolerence,
                 @"The response time was not respected (expected: %d, got: %d)", kResponseTime, -[startDate timeIntervalSinceNow]);
}

-(void)test_NSURLConnection_sendSyncronousRequest_parallelQueue
{
    [[[[NSOperationQueue alloc] init] autorelease] addOperationWithBlock:^{
        [self test_NSURLConnection_sendSyncronousRequest_mainQueue];
        [self notifyAsyncOperationDone];
    }];
    [self waitForAsyncOperationWithTimeout:3.0];
}

///////////////////////////////////////////////////////////////////////////////////
#pragma mark Single [NSURLConnection sendAsynchronousRequest:queue:completionHandler:]
///////////////////////////////////////////////////////////////////////////////////

-(void)_test_NSURLConnection_sendAsyncronousRequest_onOperationQueue:(NSOperationQueue*)queue
{
    static const NSTimeInterval kResponseTime = 2.0;
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
        return [OHHTTPStubsResponse responseWithData:testData
                                          statusCode:200
                                        responseTime:kResponseTime
                                             headers:nil];
    }];
    
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com"]];
    NSDate* startDate = [NSDate date];
    
    [NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         STAssertEqualObjects(data, testData, @"Invalid data response");
         STAssertTrue( fabs(kResponseTime+[startDate timeIntervalSinceNow]) < kResponseTimeTolerence,
                      @"The response time was not respected (expected: %d, got: %d)", kResponseTime, -[startDate timeIntervalSinceNow]);
         
         [self notifyAsyncOperationDone];
     }];
    
    [self waitForAsyncOperationWithTimeout:kResponseTime+1.0];
}


-(void)test_NSURLConnection_sendAsyncronousRequest_mainQueue
{
    [self _test_NSURLConnection_sendAsyncronousRequest_onOperationQueue:[NSOperationQueue mainQueue]];
}


-(void)test_NSURLConnection_sendAsyncronousRequest_parallelQueue
{
    [self _test_NSURLConnection_sendAsyncronousRequest_onOperationQueue:[[[NSOperationQueue alloc] init] autorelease]];
}


///////////////////////////////////////////////////////////////////////////////////
#pragma mark Multiple Parallel [NSURLConnection sendAsynchronousRequest:queue:completionHandler:]
///////////////////////////////////////////////////////////////////////////////////

-(void)_test_NSURLConnection_sendMultipleAsyncronousRequestsOnOperationQueue:(NSOperationQueue*)queue
{
    NSData* (^dataForRequest)(NSURLRequest*) = ^(NSURLRequest* req) {
        return [[NSString stringWithFormat:@"<Response for URL %@>",req.URL.absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
    };
    
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
        NSData* retData = dataForRequest(request);
        NSTimeInterval responseTime = [request.URL.lastPathComponent doubleValue];
        return [OHHTTPStubsResponse responseWithData:retData
                                          statusCode:200
                                        responseTime:responseTime
                                             headers:nil];
    }];
    
    // Reusable code to send a request that will respond in the given response time
    void (^sendAsyncRequest)(NSTimeInterval) = ^(NSTimeInterval responseTime)
    {
        NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://dummyrequest/concurrent/time/%f",responseTime]]];
        [SenTestLog testLogWithFormat:@"== Sending request %@\n", req];
        NSDate* startDate = [NSDate date];
        [NSURLConnection sendAsynchronousRequest:req queue:queue completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
         {
             [SenTestLog testLogWithFormat:@"== Received response for request %@\n", req];
             STAssertEqualObjects(data, dataForRequest(req), @"Invalid data response");
             STAssertTrue( fabs(responseTime+[startDate timeIntervalSinceNow]) < kResponseTimeTolerence,
                          @"The response time was not respected (expected: %d, got: %d)", responseTime, -[startDate timeIntervalSinceNow]);
             
             [self notifyAsyncOperationDone];
         }];
    };

    sendAsyncRequest(3.0); // send this one first, should receive last
    sendAsyncRequest(2.0); // send this one next, shoud receive 2nd
    sendAsyncRequest(1.0); // send this one last, should receive first

    [self waitForAsyncOperations:3 withTimeout:4.0]; // time out after 4s because the requests should run concurrently and all should be done in ~3s
}

-(void)test_NSURLConnection_sendMultipleAsyncronousRequests_mainQueue
{
    [self _test_NSURLConnection_sendMultipleAsyncronousRequestsOnOperationQueue:[NSOperationQueue mainQueue]];
}

-(void)test_NSURLConnection_sendMultipleAsyncronousRequests_parallelQueue
{
    [self _test_NSURLConnection_sendMultipleAsyncronousRequestsOnOperationQueue:[[[NSOperationQueue alloc] init] autorelease]];
}

@end
