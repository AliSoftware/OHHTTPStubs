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
#import "OHHTTPStubs.h"

@interface AFNetworkingTests : AsyncSenTestCase @end

@implementation AFNetworkingTests

-(void)test_AFHTTPRequestOperation
{
    static const NSTimeInterval kResponseTime = 1.0;
    NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 responseTime:kResponseTime headers:nil];
    }];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    AFHTTPRequestOperation* op = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    __block id response = nil;
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        response = [[responseObject retain] autorelease];
        [self notifyAsyncOperationDone];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        STFail(@"Unexpected network failure");
        [self notifyAsyncOperationDone];
    }];
    [op start];
    
    [self waitForAsyncOperationWithTimeout:kResponseTime+0.5];
    
    STAssertEqualObjects(response, expectedResponse, @"Unexpected data received");
}

@end
