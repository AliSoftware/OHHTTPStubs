//
//  NSURLSessionTests.m
//  OHHTTPStubs
//
//  Created by Nick Donaldson on 10/5/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import "AsyncSenTestCase.h"
#import "OHHTTPStubs.h"
#import "OHHTTPStubsResponse+JSON.h"

@interface NSURLSessionTests : AsyncSenTestCase @end

@implementation NSURLSessionTests

- (void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
}

// Normal stubbing should work fine for the shared session
- (void)test_DefaultSharedNSURLSession
{
    if ([NSURLSession class])
    {
        static const NSTimeInterval kRequestTime = 1.0;
        static const NSTimeInterval kResponseTime = 1.0;
        NSDictionary *expectedResponseDict = @{@"Success" : @"Yes"};
        
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return YES;
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithJSONObject:expectedResponseDict statusCode:200 headers:nil]
                    requestTime:kRequestTime responseTime:kResponseTime];
        }];
        
        NSURLSession *session = [NSURLSession sharedSession];
        
        __block __strong id dataResponse = nil;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:3333"]];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        NSURLSessionDataTask *task =  [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                     STAssertNil(error, @"Unexpected error");
                                                     if (!error)
                                                     {
                                                         NSError *jsonError = nil;
                                                         NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                         STAssertNil(jsonError, @"Unexpected error deserializing JSON response");
                                                         dataResponse = jsonObject;
                                                     }
                                                     [self notifyAsyncOperationDone];
                                                 }];

        [task resume];
        
        [self waitForAsyncOperationWithTimeout:kRequestTime+kResponseTime+0.5];
        
        STAssertEqualObjects(dataResponse, expectedResponseDict, @"Unexpected data received");
        
    }
}

@end
