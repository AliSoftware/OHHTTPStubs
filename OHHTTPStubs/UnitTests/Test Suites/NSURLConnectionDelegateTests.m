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

@interface NSURLConnectionDelegateTests : AsyncSenTestCase <NSURLConnectionDataDelegate> @end

static const NSTimeInterval kResponseTimeTolerence = 0.2;

@implementation NSURLConnectionDelegateTests
{
    NSMutableData* _data;
    NSError* _error;
}

///////////////////////////////////////////////////////////////////////////////////
#pragma mark Global Setup + NSURLConnectionDelegate implementation
///////////////////////////////////////////////////////////////////////////////////

-(void)setUp
{
    [super setUp];
    _data = [[NSMutableData alloc] init];
}

-(void)tearDown
{
    [_data release];
    // in case the test timed out and finished before a running NSURLConnection ended,
    // we may continue receive delegate messages anyway if we forgot to cancel.
    // So avoid sending messages to deallocated object in this case by ensuring we reset it to nil
    _data = nil;
    [_error release];
    _error = nil;
    [super tearDown];
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
    _error = [error retain];
    [self notifyAsyncOperationDone];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self notifyAsyncOperationDone];
}



///////////////////////////////////////////////////////////////////////////////////
#pragma mark NSURLConnection + Delegate
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLConnectionDelegate_success
{
    static const NSTimeInterval kResponseTime = 1.0;
    NSData* testData = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:testData
                                          statusCode:200
                                        responseTime:kResponseTime
                                             headers:nil];
    }];
        
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startDate = [NSDate date];
    
    NSURLConnection* cxn = [NSURLConnection connectionWithRequest:req delegate:self];
    
    [self waitForAsyncOperationWithTimeout:kResponseTime+kResponseTimeTolerence];
    
    STAssertEqualObjects(_data, testData, @"Invalid data response");
    STAssertNil(_error, @"Received unexpected network error %@", _error);
    STAssertEqualsWithAccuracy(-[startDate timeIntervalSinceNow], kResponseTime, kResponseTimeTolerence, @"Invalid response time");
    
    // in case we timed out before the end of the request (test failed), cancel the request to avoid further delegate method calls
    [cxn cancel];
}

-(void)test_NSURLConnectionDelegate_error
{
    static const NSTimeInterval kResponseTime = 1.0;
    NSError* expectedError = [NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:nil];
    
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        OHHTTPStubsResponse* resp = [OHHTTPStubsResponse responseWithError:expectedError];
        resp.responseTime = kResponseTime;
        return resp;
    }];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSDate* startDate = [NSDate date];
    
    NSURLConnection* cxn = [NSURLConnection connectionWithRequest:req delegate:self];
    
    [self waitForAsyncOperationWithTimeout:kResponseTime+kResponseTimeTolerence];
    
    STAssertEquals(_data.length, 0U, @"Received unexpected network data %@", _data);
    STAssertEqualObjects(_error.domain, expectedError.domain, @"Invalid error response domain");
    STAssertEquals(_error.code, expectedError.code, @"Invalid error response code");
    STAssertEqualsWithAccuracy(-[startDate timeIntervalSinceNow], kResponseTime, kResponseTimeTolerence, @"Invalid response time");
    
    // in case we timed out before the end of the request (test failed), cancel the request to avoid further delegate method calls
    [cxn cancel];
}


///////////////////////////////////////////////////////////////////////////////////
#pragma mark Cancelling requests
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLConnection_cancel
{
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:[@"<this data should never have time to arrive>" dataUsingEncoding:NSUTF8StringEncoding]
                                          statusCode:500
                                        responseTime:1.5
                                             headers:nil];
    }];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSURLConnection* cxn = [NSURLConnection connectionWithRequest:req delegate:self];
    
    [self waitForTimeout:0.5];
    [cxn cancel];
    [self waitForTimeout:1.5];
    
    STAssertEquals(_data.length, 0U, @"Received unexpected data but the request should have been cancelled");
    STAssertNil(_error, @"Received unexpected network error but the request should have been cancelled");
    
    // in case we timed out before the end of the request (test failed), cancel the request to avoid further delegate method calls
    [cxn cancel];
}


///////////////////////////////////////////////////////////////////////////////////
#pragma mark Cancelling requests
///////////////////////////////////////////////////////////////////////////////////

-(void)test_NSURLConnection_cookies
{
    NSString* const cookieName = @"SESSIONID";
    NSString* const cookieValue = [[NSProcessInfo processInfo] globallyUniqueString];
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* cookie = [NSString stringWithFormat:@"%@=%@;", cookieName, cookieValue];
        NSDictionary* headers = [NSDictionary dictionaryWithObject:cookie forKey:@"Set-Cookie"];
        return [OHHTTPStubsResponse responseWithData:[@"Yummy cookies" dataUsingEncoding:NSUTF8StringEncoding]
                                          statusCode:200
                                        responseTime:0
                                             headers:headers];
    }];
    
    // Set the cookie accept policy to accept all cookies from the main document domain
    // (especially in case the previous policy was "NSHTTPCookieAcceptPolicyNever")
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSHTTPCookieAcceptPolicy previousAcceptPolicy = [cookieStorage cookieAcceptPolicy]; // keep it to restore later
    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain];
    
    // Send the request and wait for the response containing the Set-Cookie headers
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    NSURLConnection* cxn = [NSURLConnection connectionWithRequest:req delegate:self];
    [self waitForAsyncOperationWithTimeout:kResponseTimeTolerence];
    [cxn cancel]; // In case we timed out (test failed), cancel the request to avoid further delegate method calls
    
    
    /* Check that the cookie has been properly stored */
    NSArray* cookies = [cookieStorage cookiesForURL:req.URL];
    BOOL cookieFound = NO;
    for (NSHTTPCookie* cookie in cookies)
    {
        if ([cookie.name isEqualToString:cookieName])
        {
            cookieFound = YES;
            STAssertEqualObjects(cookie.value, cookieValue, @"The cookie does not have the expected value");
        }
    }
    STAssertTrue(cookieFound, @"The cookie was not stored as expected");
    

    // As a courtesy, restore previous policy before leaving
    [cookieStorage setCookieAcceptPolicy:previousAcceptPolicy];

}

@end
