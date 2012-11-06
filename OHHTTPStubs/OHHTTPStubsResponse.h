/***********************************************************************************
 *
 * Copyright (c) 2012 Olivier Halligon
 *
 * Original idea: https://github.com/InfiniteLoopDK/ILTesting
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

#define OHHTTPStubsResponseUseStub (OHHTTPStubsResponse*)@"DummyStub"
#define OHHTTPStubsResponseDontUseStub (OHHTTPStubsResponse*)nil

// Standard download speeds.
extern const double
OHHTTPStubsDownloadSpeedGPRS,
OHHTTPStubsDownloadSpeedEDGE,
OHHTTPStubsDownloadSpeed3G,
OHHTTPStubsDownloadSpeed3GPlus,
OHHTTPStubsDownloadSpeedWifi;


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interface

@interface OHHTTPStubsResponse : NSObject

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Properties

@property(nonatomic, retain) NSDictionary* httpHeaders;
@property(nonatomic, assign) int statusCode;
@property(nonatomic, retain) NSData* responseData;
//! @note if responseTime<0, it is interpreted as a download speed in KBps ( -200 => 200KB/s )
@property(nonatomic, assign) NSTimeInterval responseTime;
@property(nonatomic, retain) NSError* error;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class Methods

+(OHHTTPStubsResponse*)responseWithData:(NSData*)data
                             statusCode:(int)statusCode
                           responseTime:(NSTimeInterval)responseTime
                                headers:(NSDictionary*)httpHeaders;
+(OHHTTPStubsResponse*)responseWithFile:(NSString*)fileName
                             statusCode:(int)statusCode
                           responseTime:(NSTimeInterval)responseTime
                                headers:(NSDictionary*)httpHeaders;
+(OHHTTPStubsResponse*)responseWithFile:(NSString*)fileName
                            contentType:(NSString*)contentType
                           responseTime:(NSTimeInterval)responseTime;
+(OHHTTPStubsResponse*)responseWithError:(NSError*)error;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Instance Methods

-(OHHTTPStubsResponse*)initWithData:(NSData*)data
                         statusCode:(int)statusCode
                       responseTime:(NSTimeInterval)responseTime
                            headers:(NSDictionary*)httpHeaders;
-(OHHTTPStubsResponse*)initWithError:(NSError*)error;

@end
