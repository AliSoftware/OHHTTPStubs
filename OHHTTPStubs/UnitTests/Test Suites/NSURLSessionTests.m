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


- (void)_test_NSURLSession:(NSURLSession*)session
               jsonForStub:(id)json
                completion:(void(^)(NSError* errorResponse,id jsonResponse))completion
{
    if ([NSURLSession class])
    {
        static const NSTimeInterval kRequestTime = 1.0;
        static const NSTimeInterval kResponseTime = 1.0;
        
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return YES;
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithJSONObject:json statusCode:200 headers:nil]
                    requestTime:kRequestTime responseTime:kResponseTime];
        }];
        
        __block __strong id dataResponse = nil;
        __block __strong NSError* errorResponse = nil;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://unknownhost:666"]];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        NSURLSessionDataTask *task =  [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            errorResponse = error;
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
        
        completion(errorResponse, dataResponse);
    }
}

// Normal stubbing should work fine for the shared session
- (void)test_SharedNSURLSession
{
    if ([NSURLSession class])
    {
        NSURLSession *session = [NSURLSession sharedSession];
        
        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            STAssertNil(errorResponse, @"Unexpected error");
            STAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];
    }
    else
    {
        NSLog(@"Test skipped because the NSURLSession class is not available on this iOS version");
    }
}

- (void)test_NSURLSessionDefaultConfig
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            STAssertNil(errorResponse, @"Unexpected error");
            STAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];
    }
    else
    {
        NSLog(@"Test skipped because the NSURLSessionConfiguration & NSURLSession classes are not available on this iOS version");
    }
}

- (void)test_NSURLSessionEphemeralConfig
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            STAssertNil(errorResponse, @"Unexpected error");
            STAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];
    }
    else
    {
        NSLog(@"Test skipped because the NSURLSessionConfiguration & NSURLSession classes are not available on this iOS version");
    }
}

- (void)test_NSURLSessionDefaultConfig_Disabled
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        [OHHTTPStubs setEnabled:NO forSessionConfiguration:config]; // Disable stubs for this session
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            // Stubs were disable for this session, so we should get an error instead of the stubs data
            STAssertNotNil(errorResponse, @"Expected error but none found");
            STAssertNil(jsonResponse, @"Data should not have been received as stubs should be disabled");
        }];
    }
    else
    {
        NSLog(@"Test skipped because the NSURLSessionConfiguration & NSURLSession classes are not available on this iOS version");
    }
}

@end
