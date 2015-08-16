//
//  OHHTTPStubs+Mocktail.h
//  CardCompanion
//
//  Created by Wang, Sunny on 7/30/15.
//

#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/Compatibility.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error codes for the OHHTTPStubs Mocktail category
 */
typedef NS_ENUM(NSInteger, OHHTTPStubsMocktailError) {
    /** The specified path does not exist */
    OHHTTPStubsMocktailErrorPathDoesNotExist = 1,
    /** The specified path was not readable */
    OHHTTPStubsMocktailErrorPathFailedToRead,
    /** The specified path is not a directory */
    OHHTTPStubsMocktailErrorPathIsNotFolder,
    /** The specified file is not a valid Mocktail file */
    OHHTTPStubsMocktailErrorInvalidFileFormat,
    /** The specified Mocktail file has invalid headers */
    OHHTTPStubsMocktailErrorInvalidFileHeader,
    /** An unexpected internal error occured */
    OHHTTPStubsMocktailErrorInternalError
};

extern NSString* const MocktailErrorDomain;

@interface OHHTTPStubs (Mocktail)

/**
 * Add a stub given a file in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * This method will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and
 * response body, and use them to add a stub.
 *
 * @param fileName The name of the mocktail file (without extension of '.tail') in the Mocktail format.
 * @param bundleOrNil The bundle in which the mocktail file is located. If `nil`, the `[NSBundle bundleForClass:self.class]` will be used.
 * @param error An out value that returns any error encountered during stubbing. Returns an NSError object if any error; otherwise returns nil.
 *
 * @return a stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+(id<OHHTTPStubsDescriptor>)stubRequestsUsingMocktailNamed:(NSString *)fileName inBundle:(nullable NSBundle*)bundleOrNil error:(NSError **)error;

/**
 * Add a stub given a file URL in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * This method will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and
 * response body, and use them to add a stub.
 *
 * @param fileURL The URL pointing to the file in the Mocktail format.
 * @param error An out value that returns any error encountered during stubbing. Returns an NSError object if any error; otherwise returns nil.
 *
 * @return a stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+(id<OHHTTPStubsDescriptor>)stubRequestsUsingMocktail:(NSURL *)fileURL error:(NSError **)error;

/**
 * Add stubs using files under a folder in the format of Mocktail as defined at https://github.com/square/objc-mocktail.
 *
 * This method will retrieve all the files under the folder; for each file with surfix of ".tail", it will split the HTTP method Regex, the absolute URL Regex, the headers, the HTTP status code and response body, and use them to add a stub.
 *
 * @param path The name of the folder containing files in the Mocktail format.
 * @param bundleOrNil The bundle in which the path is located. If `nil`, the `[NSBundle bundleForClass:self.class]` will be used.
 * @param error An out value that returns any error encountered during stubbing. Returns an NSError object if any error; otherwise returns nil.
 *
 * @return an array of stub descriptor that uniquely identifies the stub and can be later used to remove it with
 * `removeStub:`.
 */
+(NSArray *)stubRequestsUsingMocktailsAtPath:(NSString *)path inBundle:(nullable NSBundle*)bundleOrNil error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
