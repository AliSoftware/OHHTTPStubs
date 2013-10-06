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

@end
