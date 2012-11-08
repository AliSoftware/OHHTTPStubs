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

#import "OHHTTPStubsResponse.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Defines & Constants

const double OHHTTPStubsDownloadSpeedGPRS   =-    56 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeedEDGE   =-   128 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeed3G     =-  3200 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeed3GPlus =-  7200 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeedWifi   =- 12000 / 8; // kbps -> KB/s

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation OHHTTPStubsResponse

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Synthesize

@synthesize httpHeaders = httpHeaders_;
@synthesize statusCode = statusCode_;
@synthesize responseData = responseData_;
@synthesize responseTime = _responseTime;
@synthesize error = error_;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Setup & Teardown

-(OHHTTPStubsResponse*)initWithData:(NSData*)data
                         statusCode:(int)statusCode
                       responseTime:(NSTimeInterval)responseTime
                            headers:(NSDictionary*)httpHeaders
{
    self = [super init];
    if (self) {
        self.responseData = data;
        self.statusCode = statusCode;
        self.httpHeaders = httpHeaders;
        self.responseTime = responseTime;
    }
    return self;
}

-(OHHTTPStubsResponse*)initWithError:(NSError*)error
{
    self = [super init];
    if (self) {
        self.error = error;
    }
    return self;
}

#if ! __has_feature(objc_arc)
-(void)dealloc
{
    self.httpHeaders = nil;
    self.statusCode = 0;
    self.responseData = nil;
    self.responseTime = 0;
    self.error = nil;
    [super dealloc];
}
#endif

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class Methods

+(OHHTTPStubsResponse*)responseWithData:(NSData*)data
                             statusCode:(int)statusCode
                           responseTime:(NSTimeInterval)responseTime
                                headers:(NSDictionary*)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithData:data
                                                    statusCode:statusCode
                                                  responseTime:responseTime
                                                       headers:httpHeaders];
#if ! __has_feature(objc_arc)
    [response autorelease];
#endif
    return response;
}

+(OHHTTPStubsResponse*)responseWithFile:(NSString*)fileName
                             statusCode:(int)statusCode
                           responseTime:(NSTimeInterval)responseTime
                                headers:(NSDictionary*)httpHeaders
{
    NSString* basename = [fileName stringByDeletingPathExtension];
    NSString* extension = [fileName pathExtension];
	NSString* filePath = [[NSBundle bundleForClass:[self class]] pathForResource:basename ofType:extension];
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    return [self responseWithData:data statusCode:statusCode responseTime:responseTime headers:httpHeaders];
}

+(OHHTTPStubsResponse*)responseWithFile:(NSString*)fileName
                            contentType:(NSString*)contentType
                           responseTime:(NSTimeInterval)responseTime
{
    NSDictionary* headers = [NSDictionary dictionaryWithObject:contentType forKey:@"Content-Type"];
    return [self responseWithFile:fileName statusCode:200 responseTime:responseTime headers:headers];
}


+(OHHTTPStubsResponse*)responseWithError:(NSError*)error
{
    OHHTTPStubsResponse* response = [[self  alloc] initWithError:error];
#if ! __has_feature(objc_arc)
    [response autorelease];
#endif
    return response;
}


@end
