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


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Imports

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Defines & Constants

// Standard download speeds.
extern const double
OHHTTPStubsDownloadSpeedGPRS,
OHHTTPStubsDownloadSpeedEDGE,
OHHTTPStubsDownloadSpeed3G,
OHHTTPStubsDownloadSpeed3GPlus,
OHHTTPStubsDownloadSpeedWifi;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

/*! Stubs Response. This describes a stubbed response to be returned by the URL Loading System, including its
 HTTP headers, body, statusCode and response time. */
@interface OHHTTPStubsResponse : NSObject

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Properties

@property(nonatomic, strong) NSDictionary* httpHeaders;
@property(nonatomic, assign) int statusCode;
@property(nonatomic, strong) NSInputStream* inputStream;
@property(nonatomic, assign) unsigned long long dataSize;
@property(nonatomic, assign) NSTimeInterval requestTime; //!< Defaults to 0.0
//! @note if responseTime<0, it is interpreted as a download speed in KBps ( -200 => 200KB/s )
@property(nonatomic, assign) NSTimeInterval responseTime;
@property(nonatomic, strong) NSError* error;




////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commodity Constructors
/*! @name Commodity */

/* -------------------------------------------------------------------------- */
#pragma mark > Building response from NSData

/*! Builds a response given raw data.
 @note Internally calls `-initWithInputStream:dataSize:statusCode:headers:` with and inputStream build from the NSData.
 
 @param data The raw data to return in the response
 @param statusCode The HTTP Status Code to use in the response
 @param httpHeaders The HTTP Headers to return in the response
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
+(instancetype)responseWithData:(NSData*)data
                     statusCode:(int)statusCode
                        headers:(NSDictionary*)httpHeaders;


/* -------------------------------------------------------------------------- */
#pragma mark > Building response from a file

/*! Useful macro to build a path given a file name and a bundle.
 @param fileName The name of the file to get the path to, including file extension
 @param bundleOrNil The bundle in which the file is located. If nil, the application bundle (`[NSBundle bundleForClass:self.class]`) is used
 @return The path of the given file in the given bundle
 */
#define OHPathForFileInBundle(fileName,bundleOrNil) ({ \
  [(bundleOrNil?:[NSBundle bundleForClass:self.class]) pathForResource:[fileName stringByDeletingPathExtension] ofType:[fileName pathExtension]]; \
})

/*! Useful macro to build a path to a file in the Documents's directory in the app sandbox, used by iTunes File Sharing for example.
 @param fileName The name of the file to get the path to, including file extension
 @return The path of the file in the Documents directory in your App Sandbox
 */
#define OHPathForFileInDocumentsDir(fileName) ({ \
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); \
  NSString *basePath = (paths.count > 0) ? [paths objectAtIndex:0] : nil; \
  [basePath stringByAppendingPathComponent:fileName]; \
})

/*! Useful macro to build an NSBundle located in the application's resources simply from its name
 @param bundleBasename The base name, without extension (extension is assumed to be ".bundle").
 @return The NSBundle object representing the bundle with the given basename located in your application's resources.
 */
#define OHResourceBundle(bundleBasename) ({ \
    [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:bundleBasename ofType:@"bundle"]]; \
})


/*! Builds a response given a file path, the status code and headers.
 @param filePath The file path that contains the response body to return.
 @param statusCode The HTTP Status Code to use in the response
 @param httpHeaders The HTTP Headers to return in the response
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 @note It is encouraged to use the `OHPathForFileInBundle(fileName, bundleOrNil)` and `OHResourceBundle(bundleBasename)` macros
       to easily build a path to a file located in the app bundle or any arbitrary bundle.
       Likewise, you may use the `OHPathForFileInDocumentsDir(fileName)` macro to build a path to a file located in
       the Documents directory of your application' sandbox.
 */
+(instancetype)responseWithFileAtPath:(NSString *)filePath
                           statusCode:(int)statusCode
                              headers:(NSDictionary*)httpHeaders;

/* -------------------------------------------------------------------------- */
#pragma mark > Building an error response

/*! Builds a response that corresponds to the given error
 @param error The error to use in the stubbed response.
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 @note For example you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]`
 */
+(instancetype)responseWithError:(NSError*)error;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commotidy Setters

/*! Set the `responseTime` of the `OHHTTPStubsResponse` and return `self`. Useful for chaining method calls.
 
 _Usage example:_
 <pre>return [[OHHTTPStubsReponse responseWithData:data statusCode:200 headers:nil] responseTime:5.0];</pre>
 
 @param responseTime If positive, the amount of time used to send the entire response.
                     If negative, the rate in KB/s at which to send the response data.
                     Useful to simulate slow networks for example. You may use the OHHTTPStubsDownloadSpeed* constants here.
 @return `self` (= the same `OHHTTPStubsResponse` that was the target of this method). Useful for chaining method calls.
 */
-(instancetype)responseTime:(NSTimeInterval)responseTime;

/*! Set both the `requestTime` and the `responseTime` of the `OHHTTPStubsResponse` at once. Useful for chaining method calls.
 
 _Usage example:_
 <pre>return [[OHHTTPStubsReponse responseWithData:data statusCode:200 headers:nil]
               requestTime:1.0 responseTime:5.0];</pre>
 
 @param requestTime The time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime If positive, the amount of time used to send the entire response.
                     If negative, the rate in KB/s at which to send the response data.
                     Useful to simulate slow networks for example. You may use the OHHTTPStubsDownloadSpeed* constants here.
 @return `self` (= the same `OHHTTPStubsResponse` that was the target of this method). Useful for chaining method calls.
 */
-(instancetype)requestTime:(NSTimeInterval)requestTime responseTime:(NSTimeInterval)responseTime;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initializers
/*! @name Initializers */

/*! Designed initializer. Initialize a response with the given input stream, dataSize, statusCode and headers.
 @param inputStream The input stream that will provide the data to return in the response
 @param dataSize The size of the data in the stream.
 @param statusCode The HTTP Status Code to use in the response
 @param httpHeaders The HTTP Headers to return in the response
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 @note You will probably never need to call this method yourself. Prefer the other initializers (that will call this method eventually)
 */
-(instancetype)initWithInputStream:(NSInputStream*)inputStream
                          dataSize:(unsigned long long)dataSize
                        statusCode:(int)statusCode
                           headers:(NSDictionary*)httpHeaders;


/*! Initialize a response with a given file path, statusCode and headers.
 @param filePath The file path of the data to return in the response
 @param statusCode The HTTP Status Code to use in the response
 @param httpHeaders The HTTP Headers to return in the response
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 @note This method simply builds the NSInputStream, compute the file size, and then call `-initWithInputStream:dataSize:statusCode:headers:`
 */
-(instancetype)initWithFileAtPath:(NSString*)filePath
                       statusCode:(int)statusCode
                          headers:(NSDictionary*)httpHeaders;


/*! Initialize a response with the given data, statusCode and headers.
 @param data The raw data to return in the response
 @param statusCode The HTTP Status Code to use in the response
 @param httpHeaders The HTTP Headers to return in the response
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
-(instancetype)initWithData:(NSData*)data
                 statusCode:(int)statusCode
                    headers:(NSDictionary*)httpHeaders;


/*! Designed initializer. Initialize a response with the given error.
 @param error The error to use in the stubbed response.
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 @note For example you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]`
 */
-(instancetype)initWithError:(NSError*)error;

@end
