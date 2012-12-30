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

@interface NSURLConnectionDelegateTests : AsyncSenTestCase <NSURLConnectionDataDelegate> @end

static const NSTimeInterval kResponseTimeTolerence = 0.05;

@implementation NSURLConnectionDelegateTests
{
    NSMutableData* _data;
}

///////////////////////////////////////////////////////////////////////////////////
#pragma mark NSURLConnection + Delegate
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLConnectionDelegate
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
    
    if ([NSURLConnection connectionWithRequest:req delegate:self])
    {
        _data = [[NSMutableData alloc] init];
    }
    
    [self waitForAsyncOperationWithTimeout:kResponseTime+1];
    
    STAssertEqualObjects(_data, testData, @"Invalid data response");
    STAssertTrue( fabs(kResponseTime+[startDate timeIntervalSinceNow]) < kResponseTimeTolerence,
                 @"The response time was not respected (expected: %d, got: %d)", kResponseTime, -[startDate timeIntervalSinceNow]);
    
    [_data release];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_data setLength:0U];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    STFail(@"Request failed with error %@", error);
    [self notifyAsyncOperationDone];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self notifyAsyncOperationDone];
}

@end
