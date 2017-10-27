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

#import <Availability.h>
// Compile this only if SDK version (…MAX_ALLOWED) is iOS7+/10.9+ because NSURLSession is a class only known starting these SDKs
// (this code won't compile if we use an eariler SDKs, like when building with Xcode4)
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) \
 || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090) \
 || (defined(__TV_OS_VERSION_MIN_REQUIRED) || defined(__WATCH_OS_VERSION_MIN_REQUIRED))

#import <XCTest/XCTest.h>

#if OHHTTPSTUBS_USE_STATIC_LIBRARY
#import "OHHTTPStubs.h"
#import "OHHTTPStubsResponse+JSON.h"
#import "NSURLRequest+HTTPBodyTesting.h"
#else
@import OHHTTPStubs;
#endif

@interface NSURLSessionTests : XCTestCase <NSURLSessionDataDelegate, NSURLSessionTaskDelegate> @end

@implementation NSURLSessionTests
{
    NSMutableData* _receivedData;
    XCTestExpectation* _taskDidCompleteExpectation;
    BOOL _shouldFollowRedirects;
}

- (void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
    _receivedData = nil;
    _shouldFollowRedirects = YES;
}

- (void)_test_NSURLSession:(NSURLSession*)session
               jsonForStub:(id)json
                completion:(void(^)(NSError* errorResponse,id jsonResponse))completion
{
    if ([NSURLSession class])
    {
        static const NSTimeInterval kRequestTime = 0.0;
        static const NSTimeInterval kResponseTime = 0.2;

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return YES;
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithJSONObject:json statusCode:200 headers:nil]
                    requestTime:kRequestTime responseTime:kResponseTime];
        }];

        XCTestExpectation* expectation = [self expectationWithDescription:@"NSURLSessionDataTask completed"];

        __block __strong id dataResponse = nil;
        __block __strong NSError* errorResponse = nil;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"foo://unknownhost:666"]];
        request.HTTPMethod = @"GET";
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
                XCTAssertNil(jsonError, @"Unexpected error deserializing JSON response");
                dataResponse = jsonObject;
            }
            [expectation fulfill];
        }];

        [task resume];

        [self waitForExpectationsWithTimeout:kRequestTime+kResponseTime+0.5 handler:^(NSError * _Nullable error) {
            completion(errorResponse, dataResponse);
        }];
    }
}

- (void)_test_redirect_NSURLSession:(NSURLSession*)session
                        jsonForStub:(id)json
                         httpMethod:(NSString *) httpMethod
                           httpBody:(NSData *) httpBody
                         httpStatus:(int) httpStatusCode
                         completion:(void(^)(NSError* errorResponse, NSHTTPURLResponse *response, id jsonResponse))completion
{
    if ([NSURLSession class])
    {
        static const NSTimeInterval kRequestTime = 0.2;
        static const NSTimeInterval kResponseTime = 0.2;
        __block NSData *blockData1 = [[NSData alloc] init];
        __block NSData *blockData2 = [[NSData alloc] init];
        __block NSMutableDictionary *jsonResponse1;
        __block NSMutableDictionary *jsonResponse2;

		//First redirect
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [[[request URL] path] isEqualToString:@""];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            NSDictionary *headers = @{ @"Location": @"foo://unknownhost:666/elsewhere" };

            if (request.HTTPBody)
            {
                blockData1 = request.HTTPBody;
            }
            else if (request.HTTPBodyStream)
            {
                NSInputStream *tempStream = request.HTTPBodyStream;
                uint8_t byteBuffer[4096];

                [tempStream open];
                if (tempStream.hasBytesAvailable)
                {
                    NSInteger bytesRead = [tempStream read:byteBuffer maxLength:sizeof(byteBuffer)]; //max len must match buffer size
                    blockData1 = [NSData dataWithBytes:byteBuffer length:bytesRead];
                    NSError *error;
                    NSDictionary *tempBody = [NSJSONSerialization JSONObjectWithData:blockData1 options:NSJSONReadingMutableContainers error:&error];
                    [jsonResponse1 setObject:tempBody forKey:@"originalBody"];
                    [jsonResponse1 setObject: request.HTTPMethod forKey:@"originalMethod"];
                }
                blockData1 = [NSKeyedArchiver archivedDataWithRootObject:jsonResponse1];
            }
            return [[OHHTTPStubsResponse responseWithData:[NSData new] statusCode:httpStatusCode headers:headers]
                    requestTime:kRequestTime responseTime:kResponseTime];
        }];

		//Second redirect
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [[[request URL] path] isEqualToString:@"/elsewhere"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
			jsonResponse2 = [@{} mutableCopy];
            if (request.HTTPBody)
            {
                blockData2 = request.HTTPBody;
            }
            else if (request.HTTPBodyStream)
            {
                NSInputStream *tempStream = request.HTTPBodyStream;
                uint8_t byteBuffer[4096];

                [tempStream open];
                if (tempStream.hasBytesAvailable)
                {
                    NSInteger bytesRead = [tempStream read:byteBuffer maxLength:sizeof(byteBuffer)]; //max len must match buffer size
                    blockData2 = [NSData dataWithBytes:byteBuffer length:bytesRead];
                    NSError *error;
					NSDictionary *tempBody = [NSJSONSerialization JSONObjectWithData:blockData2 options:NSJSONReadingMutableContainers error:&error];

					[jsonResponse2 setObject:tempBody forKey:@"originalBody"];
                }
            }

			[jsonResponse2 setObject:request.HTTPMethod forKey:@"originalMethod"];
            if (json)
            {
                [jsonResponse2 setObject:[json objectForKey:@"Success"] forKey:@"Success"]; //TODO: Is there any point to this? Perhaps it proves nothing?
            }
            return [[OHHTTPStubsResponse responseWithJSONObject:jsonResponse2 statusCode:200 headers:nil]
                    requestTime:kRequestTime responseTime:kResponseTime];
        }];

        XCTestExpectation* expectation = [self expectationWithDescription:@"NSURLSessionDataTask completed"];

        //Building the request.
        __block __strong NSHTTPURLResponse *redirectResponse = nil;
        __block __strong id dataResponse = nil;
        __block __strong NSError* errorResponse = nil;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"foo://unknownhost:666"]];
        request.HTTPMethod = httpMethod; // (httpStatusCode == 303 ? @"GET" : httpMethod); //RFC2616, 303 MUST set status to GET.

        if ([httpMethod isEqualToString:@"POST"] ||
            [httpMethod isEqualToString:@"PUT"] ||
            [httpMethod isEqualToString:@"PATCH"])
        {
            request.HTTPBody = httpBody;
            [request setValue:[NSString  stringWithFormat:@"%ld", httpBody.length] forHTTPHeaderField:@"Content-Length"];
        }

        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        NSURLSessionDataTask *task =  [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           errorResponse = error;
                                           if (!error)
                                           {
                                               NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
                                               if ([HTTPResponse statusCode] >= 300 && [HTTPResponse statusCode] < 400) {
                                                   redirectResponse = HTTPResponse;
                                                   if ( ![request.HTTPMethod isEqualToString:@"GET"] )
                                                   {
                                                       dataResponse = data;
                                                   }
                                               } else { //most likely a 200 status
                                                   NSError *jsonError = nil;
                                                   NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                   XCTAssertNil(jsonError, @"Unexpected error deserializing JSON response");
                                                   dataResponse = jsonObject;
                                               }
                                           }
                                           [expectation fulfill];
                                       }];

        NSDate *startTime = [NSDate date];
        [task resume];

        [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
            NSDate *finishTime = [NSDate date];
            NSTimeInterval totalResponseTime = [finishTime timeIntervalSinceDate:startTime];
            if (redirectResponse) {
                XCTAssertGreaterThanOrEqual(totalResponseTime, (kRequestTime + kResponseTime), @"Redirect did not honor request/response time");
            }
            else if (dataResponse) {
                // NSURLSession does not wait for the 3xx response to stream before starting the second request.
                // Thus, the 3xx and final responses will stream in parallel.
                XCTAssertGreaterThanOrEqual(totalResponseTime, ((2 * kRequestTime) + kResponseTime), @"Redirect or final request did not honor request/response time");
            }
        }];
        completion(errorResponse, redirectResponse, dataResponse);
    }
}

// The shared session use the same mechanism as NSURLConnection
// (based on protocols registered via +[NSURLProtocol registerClass:] and all)
// and no NSURLSessionConfiguration
- (void)test_SharedNSURLSession
{
    if ([NSURLSession class])
    {
        NSURLSession *session = [NSURLSession sharedSession];

        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_NSURLSession:session jsonForStub:json completion:^(NSError *errorResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil([jsonResponse objectForKey:@"Success"]);
            XCTAssertEqualObjects([jsonResponse objectForKey:@"Success"], [json objectForKey:@"Success"], @"Unexpected data received");
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
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
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil([jsonResponse objectForKey:@"Success"]);
            XCTAssertEqualObjects([jsonResponse objectForKey:@"Success"], [json objectForKey:@"Success"], @"Unexpected data received");
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionDefaultConfig_notFollowingRedirects
{
    _shouldFollowRedirects = NO;

    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        NSDictionary* json = @{@"Success": @"Yes"};
        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNotNil(redirectResponse, @"Redirect response should have been received");
            XCTAssertEqual(301, [redirectResponse statusCode], @"Expected 301 redirect");
            XCTAssertNil(jsonResponse, @"Unexpected data received");
        }];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

/**
 Verify that redirects of different methods and status codes are handled properly and
 that we retain the HTTP Method for specific HTTP status codes as well as the data payload.
 **/
- (void)test_NSURLSessionDefaultConfig_MethodAndDataRetention
{
    _shouldFollowRedirects = YES;

    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        NSDictionary* json = @{@"Success": @"Yes"};
        NSDictionary* jsonBody = @{@"Testing":@"OneTwoThree"};
        NSError *error;
        __block NSData * dataToPost = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        XCTAssertNil(error, @"Unexpected JSON serialization error recieved");

        /** 301 GET, HEAD, POST, PATCH **/
        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"], @"Expected the method to be the same as was sent");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"HEAD" httpBody:nil httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"HEAD"], @"Expected the method to be the same as was sent");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:nil httpMethod:@"POST" httpBody:dataToPost httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"POST"], @"Expected the method to be the same as was sent");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalBody"], @"Expected to have original body object in the JSON");
            XCTAssertEqualObjects([jsonResponse objectForKey:@"originalBody"], jsonBody, @"Expected not to lose the original posted body via redirection.");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"PATCH" httpBody:nil httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"PATCH"], @"Expected the method to be the same as was sent");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        /** 302 GET, HEAD, POST, PATCH **/
        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:302 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should have been received");
            XCTAssertNotNil(jsonResponse, @"Json Response should have been receieved");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"]isEqualToString:@"Yes"], @"Expected the round-tripped data to be unchanged!");//We probably don't care about this as it wasn't posted?
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"], @"Expected the original method to be unchanged.");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"HEAD" httpBody:nil httpStatus:302 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should have been received");
            XCTAssertNotNil(jsonResponse, @"Json Response should have been receieved");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"]isEqualToString:@"Yes"], @"Expected the round-tripped data to be unchanged!");//We probably don't care about this as it wasn't posted?
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"HEAD"], @"Expected the original method to be unchanged.");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:nil httpMethod:@"POST" httpBody:dataToPost httpStatus:302 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should have been received");
            XCTAssertNotNil(jsonResponse, @"Json Response should have been receieved");
            XCTAssertTrue([jsonResponse containsObject:jsonBody], @"Expected the round-tripped data to be unchanged!");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"POST"], @"Expected the original method to be unchanged.");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"PATCH" httpBody:nil httpStatus:302 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should have been received");
            XCTAssertNotNil(jsonResponse, @"Json Response should have been receieved");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"]isEqualToString:@"Yes"], @"Expected the round-tripped data to be unchanged!");//We probably don't care about this as it wasn't posted?
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"PATCH"], @"Expected the original method to be unchanged.");
        }];

        /** 303 GET, HEAD, POST, PATCH **/
        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:303 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"], @"Expected the original method to be unchanged.");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"HEAD" httpBody:nil httpStatus:303 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"],  @"Expected the method to be changed from POST to GET in the case of a 303");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:nil httpMethod:@"POST" httpBody:dataToPost httpStatus:303 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"], @"Expected the method to be changed from POST to GET in the case of a 303");
            XCTAssertNil([jsonResponse objectForKey:@"Testing"]); //because 303 Redirect removes post data and starts a new request as GET.
        }];

        //post with no httpBody
        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"POST" httpBody:nil httpStatus:303 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"], @"Expected the method to be changed from POST to GET in the case of a 303");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"PATCH" httpBody:nil httpStatus:303 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received");
            XCTAssertNotNil(jsonResponse, @"Expected JSON data to be received");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"],  @"Expected the method to be changed from POST to GET in the case of a 303");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        /** 307 GET, HEAD, POST, PATCH **/
        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:307 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected a JSON object in the response");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalMethod"], @"Expected to have original method object in the JSON");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"], @"Expected the original method to be unchanged.");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"HEAD" httpBody:nil httpStatus:307 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected a JSON object in the response");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalMethod"], @"Expected to have original method object in the JSON");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"HEAD"], @"Expected the original method to be unchanged.");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:nil httpMethod:@"POST" httpBody:dataToPost httpStatus:307 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected a JSON object in the response");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalMethod"], @"Expected to have original method object in the JSON");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"POST"], @"Expected the original method to be unchanged.");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalBody"], @"Expected to have original body object in the JSON");
            XCTAssertEqualObjects([jsonResponse objectForKey:@"originalBody"], jsonBody, @"Expected not to lose the original posted body via redirection.");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"PATCH" httpBody:nil httpStatus:307 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected a JSON object in the response");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalMethod"], @"Expected to have original method object in the JSON");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"PATCH"], @"Expected the original method to be unchanged.");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        /** 308 GET, HEAD, POST, PATCH **/
        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:308 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected a JSON object in the response");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalMethod"], @"Expected to have original method object in the JSON");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"GET"], @"Expected the original method to be unchanged.");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"HEAD" httpBody:nil httpStatus:308 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected a JSON object in the response");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalMethod"], @"Expected to have original method object in the JSON");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"HEAD"], @"Expected the original method to be unchanged.");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:nil httpMethod:@"POST" httpBody:dataToPost httpStatus:308 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected a JSON object in the response");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalMethod"], @"Expected to have original method object in the JSON");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"POST"], @"Expected the original method to be unchanged.");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalBody"], @"Expected to have original body object in the JSON");
            XCTAssertEqualObjects([jsonResponse objectForKey:@"originalBody"], jsonBody, @"Expected not to lose the original posted body via redirection.");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"PATCH" httpBody:nil httpStatus:308 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil(jsonResponse, @"Expected a JSON object in the response");
            XCTAssertNotNil([jsonResponse objectForKey:@"originalMethod"], @"Expected to have original method object in the JSON");
            XCTAssertTrue([[jsonResponse objectForKey:@"originalMethod"] isEqualToString:@"PATCH"], @"Expected the original method to be unchanged.");
            XCTAssertTrue([[jsonResponse objectForKey:@"Success"] isEqualToString:@"Yes"]);
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
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
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertEqualObjects(jsonResponse, json, @"Unexpected data received");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            XCTAssertNil(errorResponse, @"Unexpected error");
            XCTAssertNil(redirectResponse, @"Unexpected redirect response received");
            XCTAssertNotNil([jsonResponse objectForKey:@"Success"]);
            XCTAssertEqualObjects([jsonResponse objectForKey:@"Success"], [json objectForKey:@"Success"], @"Unexpected data received");
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
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
            XCTAssertNotNil(errorResponse, @"Expected error but none found");
            XCTAssertNil(jsonResponse, @"Data should not have been received as stubs should be disabled");
        }];

        [self _test_redirect_NSURLSession:session jsonForStub:json httpMethod:@"GET" httpBody:nil httpStatus:301 completion:^(NSError *errorResponse, NSHTTPURLResponse *redirectResponse, id jsonResponse) {
            // Stubs were disable for this session, so we should get an error instead of the stubs data
            XCTAssertNotNil(errorResponse, @"Expected error but none found");
            XCTAssertNil(redirectResponse, @"Redirect response should not have been received as stubs should be disabled");
            XCTAssertNil(jsonResponse, @"Data should not have been received as stubs should be disabled");
        }];

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSession_DataTask_DelegateMethods
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.scheme isEqualToString:@"stub"];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 headers:nil]
                    responseTime:0.5];
        }];

        _taskDidCompleteExpectation = [self expectationWithDescription:@"NSURLSessionDataTask completion delegate method called"];

        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        [[session dataTaskWithURL:[NSURL URLWithString:@"stub://foo"]] resume];

        [self waitForExpectationsWithTimeout:5 handler:nil];

        XCTAssertEqualObjects(_receivedData, expectedResponse, @"Unexpected response");

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionCustomHTTPBody
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
        NSString* expectedBodyString = @"body";

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            NSData* body = [request OHHTTPStubs_HTTPBody];
            return [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] isEqualToString:expectedBodyString];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 headers:nil]
                    responseTime:0.2];
        }];

        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        // setup for positive check
        _taskDidCompleteExpectation = [self expectationWithDescription:@"Complete successful body test"];

        NSMutableURLRequest* requestWithBody = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"stub://foo"]];
        requestWithBody.HTTPBody = [expectedBodyString dataUsingEncoding:NSUTF8StringEncoding];
        [[session dataTaskWithRequest:requestWithBody] resume];

        [self waitForExpectationsWithTimeout:5 handler:nil];
        XCTAssertEqualObjects(_receivedData, expectedResponse, @"Unexpected response: HTTP body check should be successful");

        // reset for negative check
        _taskDidCompleteExpectation = [self expectationWithDescription:@"Complete unsuccessful body test"];
        _receivedData = nil;

        requestWithBody.HTTPBody = [@"somethingElse" dataUsingEncoding:NSUTF8StringEncoding];
        [[session dataTaskWithRequest:requestWithBody] resume];

        [self waitForExpectationsWithTimeout:5 handler:nil];

        XCTAssertNil(_receivedData, @"Unexpected response: HTTP body check should not be successful");

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

- (void)test_NSURLSessionNativeHTTPBody
{
    if ([NSURLSessionConfiguration class] && [NSURLSession class])
    {
        NSData* expectedResponse = [NSStringFromSelector(_cmd) dataUsingEncoding:NSUTF8StringEncoding];
        NSString* expectedBodyString = @"body";

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            NSData* body = [request HTTPBody]; // this is not expected to work correctly
            return [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] isEqualToString:expectedBodyString];
        } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
            return [[OHHTTPStubsResponse responseWithData:expectedResponse statusCode:200 headers:nil]
                    responseTime:0.2];
        }];

        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

        _taskDidCompleteExpectation = [self expectationWithDescription:@"Complete body test"];

        NSMutableURLRequest* requestWithBody = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"stub://foo"]];
        requestWithBody.HTTPBody = [expectedBodyString dataUsingEncoding:NSUTF8StringEncoding];
        [[session dataTaskWithRequest:requestWithBody] resume];

        [self waitForExpectationsWithTimeout:5 handler:nil];
        XCTAssertNil(_receivedData, @"[request HTTPBody] is not expected to work. If this has been fixed, the OHHTTPStubs_HTTPBody can be removed.");

        [session finishTasksAndInvalidate];
    }
    else
    {
        NSLog(@"/!\\ Test skipped because the NSURLSession class is not available on this OS version. Run the tests a target with a more recent OS.\n");
    }
}

//---------------------------------------------------------------
#pragma mark - Delegate Methods

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    _receivedData = [NSMutableData new];
    completionHandler(NSURLSessionResponseAllow);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [_receivedData appendData:data];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [_taskDidCompleteExpectation fulfill];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    completionHandler(_shouldFollowRedirects ? request : nil);
}

@end

#else
#warning Unit Tests using NSURLSession were not compiled nor executed, because NSURLSession is only available since iOS7/OSX10.9 SDK. \
-------- Compile using iOS7 or OSX10.9 SDK then launch the tests on the iOS7 simulator or an OSX10.9 target for them to be executed.
#endif
