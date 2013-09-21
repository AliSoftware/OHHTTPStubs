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

#if ! __has_feature(objc_arc)
#error This file is expected to be compiled with ARC turned ON
#endif

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
#pragma mark - Commodity Constructors


#pragma mark > Building response from NSData

+(instancetype)responseWithData:(NSData*)data
                     statusCode:(int)statusCode
                        headers:(NSDictionary*)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithData:data
                                                    statusCode:statusCode
                                                       headers:httpHeaders];
    return response;
}


#pragma mark > Building response from a file

+(instancetype)responseWithFileAtPath:(NSString *)filePath
                           statusCode:(int)statusCode
                              headers:(NSDictionary *)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithFileAtPath:filePath
                                                          statusCode:statusCode
                                                             headers:httpHeaders];
    return response;
}


#pragma mark > Building an error response

+(instancetype)responseWithError:(NSError*)error
{
    OHHTTPStubsResponse* response = [[self  alloc] initWithError:error];
    return response;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commotidy Setters

-(instancetype)responseTime:(NSTimeInterval)responseTime
{
    self.responseTime = responseTime;
    return self;
}

-(instancetype)requestTime:(NSTimeInterval)requestTime responseTime:(NSTimeInterval)responseTime
{
    self.requestTime = requestTime;
    self.responseTime = responseTime;
    return self;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initializers

-(instancetype)initWithInputStream:(NSInputStream*)inputStream
                          dataSize:(unsigned long long)dataSize
                        statusCode:(int)statusCode
                           headers:(NSDictionary*)httpHeaders
{
    self = [super init];
    if (self)
    {
        self.inputStream = inputStream;
        self.dataSize = dataSize;
        self.statusCode = statusCode;
        NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:httpHeaders];
        headers[@"Content-Length"] = [NSString stringWithFormat:@"%llu",self.dataSize];
        self.httpHeaders = [NSDictionary dictionaryWithDictionary:headers];
    }
    return self;
}

-(instancetype)initWithFileAtPath:(NSString*)filePath
                       statusCode:(int)statusCode
                          headers:(NSDictionary*)httpHeaders
{
    NSInputStream* inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    NSDictionary* attributes = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:nil];
    unsigned long long fileSize = [[attributes valueForKey:NSFileSize] unsignedLongLongValue];
    self = [self initWithInputStream:inputStream
                            dataSize:fileSize
                          statusCode:statusCode
                             headers:httpHeaders];
    return self;
}

-(instancetype)initWithData:(NSData*)data
                 statusCode:(int)statusCode
                    headers:(NSDictionary*)httpHeaders
{
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:data?:[NSData data]];
    self = [self initWithInputStream:inputStream
                            dataSize:data.length
                          statusCode:statusCode
                             headers:httpHeaders];
    return self;
}

-(instancetype)initWithError:(NSError*)error
{
    self = [super init];
    if (self) {
        self.error = error;
    }
    return self;
}

-(NSString*)debugDescription
{
    return [NSString stringWithFormat:@"<%@ %p requestTime:%f responseTime:%f status:%d dataSize:%llu>",
            self.class, self, self.requestTime, self.responseTime, self.statusCode, self.dataSize];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

-(void)setRequestTime:(NSTimeInterval)requestTime
{
    NSAssert(requestTime >= 0, @"Invalid Request Time (%f) for OHHTTPStubResponse. Request time must be greater than or equal to zero",requestTime);
    _requestTime = requestTime;
}

// Deprecated!!! Use inputStream instead
-(NSData*)responseData
{
    NSData* data = nil;
    uint8_t* buffer = NULL;
    NSUInteger length = 0UL;
    if ([self.inputStream getBuffer:&buffer length:&length])
    {
        data = [NSData dataWithBytes:buffer length:length];
    }
    free(buffer);
    return data;
}

// Deprecated!!! Use inputStream instead
-(void)setResponseData:(NSData *)responseData
{
    self.inputStream = [NSInputStream inputStreamWithData:responseData];
    self.dataSize = responseData.length;
}

@end



@implementation OHHTTPStubsResponse (Deprecated)

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Deprecated Constructors

+(instancetype)responseWithData:(NSData*)data
statusCode:(int)statusCode
responseTime:(NSTimeInterval)responseTime
headers:(NSDictionary*)httpHeaders
{
    return [[self responseWithData:data
                        statusCode:statusCode
                           headers:httpHeaders]
            requestTime:(responseTime<0)?0:responseTime*0.1
            responseTime:(responseTime<0)?responseTime:responseTime*0.9];
}

+(instancetype)responseWithFile:(NSString*)fileName
statusCode:(int)statusCode
responseTime:(NSTimeInterval)responseTime
headers:(NSDictionary*)httpHeaders
{
    return [[self responseWithFileAtPath:OHPathForFileInBundle(fileName,nil)
                              statusCode:statusCode
                                 headers:httpHeaders]
            requestTime:(responseTime<0)?0:responseTime*0.1
            responseTime:(responseTime<0)?responseTime:responseTime*0.9];
}

+(instancetype)responseWithFile:(NSString*)fileName
contentType:(NSString*)contentType
responseTime:(NSTimeInterval)responseTime
{
    return [[self responseWithFileAtPath:OHPathForFileInBundle(fileName,nil)
                              statusCode:200
                                 headers:@{ @"Content-Type":contentType }]
            requestTime:(responseTime<0)?0:responseTime*0.1
            responseTime:(responseTime<0)?responseTime:responseTime*0.9];
}

-(instancetype)initWithData:(NSData*)data
statusCode:(int)statusCode
responseTime:(NSTimeInterval)responseTime
headers:(NSDictionary*)httpHeaders
{
    return [[self initWithData:data
                    statusCode:statusCode
                       headers:httpHeaders]
            requestTime:(responseTime<0)?0:responseTime*0.1
            responseTime:(responseTime<0)?responseTime:responseTime*0.9];
}

@end
