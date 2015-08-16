//
//  MockTailTests.m
//  OHHTTPStubs
//
//  Created by Wang, Sunny on 7/23/15.
//  Copyright (c) 2015 AliSoftware. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface MocktailTests : XCTestCase
@property(nonatomic, strong) NSURLSession *session;
@end

@implementation MocktailTests

- (void)setUp
{
    [super setUp];
    [OHHTTPStubs removeAllStubs];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
}

- (void)tearDown
{
    [super tearDown];
    self.session = nil;
}

- (void)testMoctTailLoginSuccess
{
    NSError *error = nil;
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    [OHHTTPStubs stubRequestsUsingMocktailNamed:@"login" inBundle:bundle error: &error];
    XCTAssertNil(error, @"Error while stubbing 'login.tail':%@", [error localizedDescription]);
    [self runLogin];
}

- (void)testMocktailsAtFolder
{
    NSError *error = nil;
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    [OHHTTPStubs stubRequestsUsingMocktailsAtPath:@"MocktailFolder" inBundle:bundle error:&error];
    XCTAssertNil(error, @"Error while stubbing Mocktails at folder 'MocktailFolder': %@", [error localizedDescription]);
    [self runLogin];
    [self runGetCards];
}

- (void)runLogin
{
    NSURL *url = [NSURL URLWithString:@"https://int-wallet.kdc.capitalone.com/dw/service/users"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    request.HTTPMethod = @"POST";
    NSDictionary *mapData = @{@"iloveit": @"walletuser",
                             @"password": @"username"};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:NULL];
    request.HTTPBody = postData;
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"NSURLSessionDataTask completed"];
    
    NSURLSessionDataTask *postDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        XCTAssertNil(error, @"Error while logging in.");
        
        NSDictionary *json = nil;
        if(!error && [@"application/json" isEqual:response.MIMEType])
        {
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        }
        
        XCTAssertNotNil(json, @"The response is not a json object");
        XCTAssertEqualObjects(json[@"status"], @"SUCCESS", @"The response does to return a successful status");
        XCTAssertNotNil(json[@"user_token"], @"The response does not contain a user token");
        
        [expectation fulfill];
    }];
    
    [postDataTask resume];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)runGetCards
{
    NSURL *url = [NSURL URLWithString:@"https://int-wallet.kdc.capitalone.com/dw/service/cards"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    request.HTTPMethod = @"GET";
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"NSURLSessionDataTask completed"];
    
    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        XCTAssertNil(error, @"Error while getting cards.");
        
        NSArray *json = nil;
        if(!error && [@"application/json" isEqual:response.MIMEType])
        {
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        }
        
        XCTAssertNotNil(json, @"The response is not a json object");
        XCTAssertEqual(json.count, 2, @"The response does not contain 2 cards");
        XCTAssertEqualObjects([json firstObject][@"embossed_name"], @"John C Smith", @"The first card owner name does not match");
        
        [expectation fulfill];
    }];
    
    [getDataTask resume];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
