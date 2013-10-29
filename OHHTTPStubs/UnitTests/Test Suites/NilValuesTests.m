//
//  NilValuesTests.m
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 14/09/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import "AsyncSenTestCase.h"
#import "OHHTTPStubs.h"

static const NSTimeInterval kResponseTimeTolerence = 0.3;

@interface NilValuesTests : AsyncSenTestCase @end

@implementation NilValuesTests

-(void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
}

- (void)test_NilData
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:nil statusCode:400 headers:nil];
    }];
    
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         STAssertEquals(data.length, (NSUInteger)0, @"Data should be empty");
         
         [self notifyAsyncOperationDone];
     }];
    
    [self waitForAsyncOperationWithTimeout:kResponseTimeTolerence];
}

- (void)test_InvalidPath
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:@"-invalid-path-" statusCode:500 headers:nil];
    }];
    
    
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.iana.org/domains/example/"]];
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         STAssertEquals(data.length, (NSUInteger)0, @"Data should be empty");
         
         [self notifyAsyncOperationDone];
     }];
    
    [self waitForAsyncOperationWithTimeout:kResponseTimeTolerence];
}

- (void)_test_NilURLAndCookieHandlingEnabled:(BOOL)handleCookiesEnabled
{
    NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithData:expectedResponse
                                          statusCode:200
                                             headers:nil];
    }];
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:nil];
    [req setHTTPShouldHandleCookies:handleCookiesEnabled];
    
    __block NSData* response = nil;
    
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error)
     {
         response = data;
         [self notifyAsyncOperationDone];
     }];
    
    [self waitForAsyncOperationWithTimeout:kResponseTimeTolerence];
    
    STAssertEqualObjects(response, expectedResponse, @"Unexpected data received");
}

- (void)test_NilURLAndCookieHandlingEnabled
{
    [self _test_NilURLAndCookieHandlingEnabled:YES];
}

- (void)test_NilURLAndCookieHandlingDisabled
{
    [self _test_NilURLAndCookieHandlingEnabled:NO];
}

@end
