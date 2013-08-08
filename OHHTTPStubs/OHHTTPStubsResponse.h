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

/*! @header
 Stubs Response. This describes a stubbed response to be returned by the URL Loading System, including its
 HTTP headers, body, statusCode and response time.
 */
@interface OHHTTPStubsResponse : NSObject

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Properties

@property(nonatomic, strong) NSDictionary* httpHeaders;
@property(nonatomic, assign) int statusCode;
@property(nonatomic, strong) NSInputStream* inputStream;
@property(nonatomic, assign) NSTimeInterval requestTime; //Default to 1.0
//! @note if responseTime<0, it is interpreted as a download speed in KBps ( -200 => 200KB/s )
@property(nonatomic, assign) NSTimeInterval responseTime;
@property(nonatomic, strong) NSError* error;
@property(nonatomic, assign) unsigned long long dataSize;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class Methods

/*! @name Commodity constructors */

/*! Builds a response given raw data
 @param data The raw data to return in the response
 @param statusCode the HTTP Status Code to use in the response
 @param requestTime the time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @param httpHeaders The HTTP Headers to return in the response
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
+(instancetype)responseWithData:(NSData*)data
                     statusCode:(int)statusCode
                    requestTime:(NSTimeInterval)requestTime
                   responseTime:(NSTimeInterval)responseTime
                        headers:(NSDictionary*)httpHeaders;

/*! Builds a response given a file in the application bundle, the status code and headers.
 @param fileName The file name and extension that contains the response body to return. The file must be in the application bundle
 @param statusCode the HTTP Status Code to use in the response
 @param requestTime the time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @param httpHeaders The HTTP Headers to return in the response
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
+(instancetype)responseWithFileInMainBundle:(NSString*)fileName
                                 statusCode:(int)statusCode
                                requestTime:(NSTimeInterval)requestTime
                               responseTime:(NSTimeInterval)responseTime
                                    headers:(NSDictionary*)httpHeaders;

/*! Builds a response given a file in the application bundle and a content type.
 @param fileName The file name and extension that contains the response body to return. The file must be in the application bundle
 @param contentType the value to use for the "Content-Type" HTTP header
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 @note HTTP Status Code 200 will be used in the response
 */
+(instancetype)responseWithFileInMainBundle:(NSString*)fileName
                                contentType:(NSString*)contentType
                               responseTime:(NSTimeInterval)responseTime;

/*! Builds a response given a message data as returned by `curl -is [url]`, that is containing both the headers and the body.
 This method will split the headers and the body and build a OHHTTPStubsReponse accordingly
 @param responseData the NSData containing the whole HTTP response, including the headers and the body
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
+(instancetype)responseWithHTTPMessageData:(NSData*)responseData
                              responseTime:(NSTimeInterval)responseTime;

/*! Builds a response given the name of a "*.response" file containing both the headers and the body.
 The response file is expected to be in the specified bundle (or the application bundle if nil).
 This method will split the headers and the body and build a OHHTTPStubsReponse accordingly
 @param responseName the name of the "*.response" file (without extension) containing the whole HTTP response (including the headers and the body)
 @param bundle the bundle in which the "*.response" file is located. If `nil`, the `[NSBundle bundleForClass:self.class]` will be used.
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
+(instancetype)responseNamed:(NSString*)responseName
                  fromBundle:(NSBundle*)bundle
                responseTime:(NSTimeInterval)responseTime;

/*! Builds a response that corresponds to the given error
 @param error The error to use in the stubbed response.
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 @note For example you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]`
 */
+(instancetype)responseWithError:(NSError*)error;
/*! Builds a response given a file path, the status code and headers.
 @param filePath The file path that contains the response body to return.
 @param statusCode the HTTP Status Code to use in the response
 @param requestTime the time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @param httpHeaders The HTTP Headers to return in the response
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
+(instancetype)responseWithFilePath:(NSString *)filePath
                         statusCode:(int)statusCode
                        requestTime:(NSTimeInterval)requestTime
                       responseTime:(NSTimeInterval)responseTime
                            headers:(NSDictionary *)httpHeaders;

/*! Builds a response given a file path and a content type.
 @param filePath The file path that contains the response body to return.
 @param contentType the value to use for the "Content-Type" HTTP header
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 @note HTTP Status Code 200 will be used in the response
 */
+(instancetype)responseWithFilePath:(NSString *)filePath
                        contentType:(NSString*)contentType
                       responseTime:(NSTimeInterval)responseTime;

/**
 * Builds a response given a JSON object for the response body, status code, and headers.
 *
 * @param jsonObject object representing the response body.
 *            Typically a `NSDictionary`; may be any object accepted by +[NSJSONSerialization dataWithJSONObject:options:error:]
 * @param statusCode the HTTP statuc doe to use in the response
 * @param responseTime the time to wait before the response is sent
 * @param httpHeaders The HTTP headers to return in the response. 
 *            If a Content-Type header is not included, "Content-Type: application/json" will be added.
 *
 * @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
+ (instancetype)responseWithJSONObject:(id)jsonObject
                            statusCode:(int)statusCode
                          responseTime:(NSTimeInterval)responseTime
                               headers:(NSDictionary*)httpHeaders;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Instance Methods
/*! Designed initializer. Initialize a response with the given input stream, statusCode, dataSize, responseTime and headers.
 @param data The raw data to return in the response
 @param statusCode the HTTP Status Code to use in the response
 @param dataSize the size of the data in the stream
 @param requestTime the time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @param httpHeaders The HTTP Headers to return in the response
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
-(instancetype)initWithInputStream:(NSInputStream*)inputStream
                        statusCode:(int)statusCode
                          dataSize:(unsigned long long)dataSize
                       requestTime:(NSTimeInterval)requestTime
                      responseTime:(NSTimeInterval)responseTime
                           headers:(NSDictionary*)httpHeaders;
/*! Initialize a response with a given file path, statusCode, responseTime and headers.
 @param filePath The file path of the data to return in the response
 @param statusCode the HTTP Status Code to use in the response
 @param requestTime the time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @param httpHeaders The HTTP Headers to return in the response
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
-(instancetype)initWithFilePath:(NSString*)filePath
                     statusCode:(int)statusCode
                    requestTime:(NSTimeInterval)requestTime
                   responseTime:(NSTimeInterval)responseTime
                        headers:(NSDictionary*)httpHeaders;
/*! Initialize a response with the given data, statusCode, responseTime and headers.
 @param data The raw data to return in the response
 @param statusCode the HTTP Status Code to use in the response
 @param requestTime the time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime if positive, the amount of time to send the entire response. If negative, the rate in KB/s to send the response data (to simulate slow networks for example). This value cannot be zero.
 @param httpHeaders The HTTP Headers to return in the response
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
-(instancetype)initWithData:(NSData*)data
                 statusCode:(int)statusCode
                requestTime:(NSTimeInterval)requestTime
               responseTime:(NSTimeInterval)responseTime
                    headers:(NSDictionary*)httpHeaders;
/*! Designed initializer. Initialize a response with the given error.
 @param error The error to use in the stubbed response.
 @return an OHHTTPStubsResponse describing the corresponding response to return by the stub
 @note For example you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]`
 */
-(instancetype)initWithError:(NSError*)error;

@end
