//
//  OHHTTPStubs+Mocktail.h
//  CardCompanion
//
//  Created by Wang, Sunny on 7/30/15.
//

#import "OHHTTPStubs.h"

typedef enum : NSInteger {
    kErrorPathDoesNotExist = 1,
    kErrorPathIsNotFolder,
    kErrorPathDoesNotRead,
    kErrorFileDoesNotExist,
    kErrorFileDoesNotRead,
    kErrorFileFormatInvalid,
    kErrorFileHeaderInvalid,
    kErrorFileInternalError
} Stub_Mocktail_Error_TYPE;

extern NSString* const MocktailErrorDomain;

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
+(id<OHHTTPStubsDescriptor>)stubRequestsUsingMocktailNamed:(NSString *)fileName error:(NSError **)error;

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
+(id<OHHTTPStubsDescriptor>)stubRequestsUsingMocktail:(NSURL *)fileURL error:(NSError **)error;

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
+(NSArray *)stubRequestsUsingMocktailsAtPath:(NSString *)path error:(NSError **)error;

@end
