//
//  OHHTTPStubs+Mocktail.h
//  CardCompanion
//
//  Created by Wang, Sunny on 7/30/15.
//  Copyright (c) 2015 Capital One. All rights reserved.
//

#import "OHHTTPStubs.h"

@interface OHHTTPStubs (Mocktail)

/**
 * Add a stub given a file in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * The response file is expected to be in the specified bundle (or the application bundle if nil).
 * This method will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and
 * response body, and use them to add a stub.
 *
 * @param fileName The name of the `"*.tail"` file (with extension) in the Mocktail format.
 *
 * @return a stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+(id<OHHTTPStubsDescriptor>)stubRequestsUsingMocktailNamed:(NSString *)fileName;

/**
 * Add a stub given a file URL in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * The response file is expected to be in the specified bundle (or the application bundle if nil).
 * This method will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and
 * response body, and use them to add a stub.
 *
 * @param fileName The name of the `"*.tail"` file (with extension) in the Mocktail format.
 *
 * @return a stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+(id<OHHTTPStubsDescriptor>)stubRequestsUsingMocktail:(NSURL *)fileURL;

/**
 * Add stubs using files under a folder URL in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * The response file is expected to be in the specified bundle (or the application bundle if nil).
 * This method will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and
 * response body, and use them to add a stub.
 *
 * @param fileName The name of the `"*.tail"` file (with extension) in the Mocktail format.
 *
 * @return an array of stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+(NSArray *)stubRequestsUsingMocktailsAt:(NSURL*)dirURL;

@end
