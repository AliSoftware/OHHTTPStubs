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
#pragma mark - Deprecated Constructors

+(instancetype)responseWithData:(NSData*)data
                     statusCode:(int)statusCode
                   responseTime:(NSTimeInterval)responseTime
                        headers:(NSDictionary*)httpHeaders
{
    return [self responseWithData:data
                       statusCode:statusCode
                      requestTime:(responseTime<0)?0:responseTime*0.1
                     responseTime:(responseTime<0)?responseTime:responseTime*0.9
                          headers:httpHeaders];
}

+(instancetype)responseWithFile:(NSString*)fileName
                     statusCode:(int)statusCode
                   responseTime:(NSTimeInterval)responseTime
                        headers:(NSDictionary*)httpHeaders
{
    return [self responseWithFileAtPath:OHPathForFileInBundle(fileName,nil)
                             statusCode:statusCode
                            requestTime:(responseTime<0)?0:responseTime*0.1
                           responseTime:(responseTime<0)?responseTime:responseTime*0.9
                                headers:httpHeaders];
}

+(instancetype)responseWithFile:(NSString*)fileName
                    contentType:(NSString*)contentType
                   responseTime:(NSTimeInterval)responseTime
{
    return [self responseWithFileAtPath:OHPathForFileInBundle(fileName,nil)
                             statusCode:200
                            requestTime:(responseTime<0)?0:responseTime*0.1
                           responseTime:(responseTime<0)?responseTime:responseTime*0.9
                                headers:@{ @"Content-Type":contentType }];
}

+(instancetype)responseWithHTTPMessageData:(NSData*)responseData
                              responseTime:(NSTimeInterval)responseTime
{
    return [self responseWithHTTPMessageData:responseData
                                 requestTime:(responseTime<0)?0:responseTime*0.1
                                responseTime:(responseTime<0)?responseTime:responseTime*0.9];
}

+(instancetype)responseNamed:(NSString*)responseName
                  fromBundle:(NSBundle*)bundle
                responseTime:(NSTimeInterval)responseTime
{
    return [self responseNamed:responseName
                      inBundle:bundle
                   requestTime:(responseTime<0)?0:responseTime*0.1
                  responseTime:(responseTime<0)?responseTime:responseTime*0.9];
}

-(instancetype)initWithData:(NSData*)data
                 statusCode:(int)statusCode
               responseTime:(NSTimeInterval)responseTime
                    headers:(NSDictionary*)httpHeaders
{
    return [self initWithData:data
                   statusCode:statusCode
                  requestTime:(responseTime<0)?0:responseTime*0.1
                 responseTime:(responseTime<0)?responseTime:responseTime*0.9
                      headers:httpHeaders];
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Commodity Constructors


#pragma mark > Building response from NSData

+(instancetype)responseWithData:(NSData*)data
                     statusCode:(int)statusCode
                    requestTime:(NSTimeInterval)requestTime
                   responseTime:(NSTimeInterval)responseTime
                        headers:(NSDictionary*)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithData:data
                                                    statusCode:statusCode
                                                   requestTime:requestTime
                                                  responseTime:responseTime
                                                       headers:httpHeaders];
    return response;
}

+ (instancetype)responseWithJSONObject:(id)jsonObject
                            statusCode:(int)statusCode
                           requestTime:(NSTimeInterval)requestTime
                          responseTime:(NSTimeInterval)responseTime
                               headers:(NSDictionary *)httpHeaders
{
    if (!httpHeaders[@"Content-Type"])
    {
        NSMutableDictionary *mutableHeaders = [httpHeaders mutableCopy];
        mutableHeaders[@"Content-Type"] = @"application/json";
        httpHeaders = mutableHeaders;
    }
    
    return [self responseWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil]
                       statusCode:statusCode
                      requestTime:requestTime
                     responseTime:responseTime
                          headers:httpHeaders
            ];
}

#pragma mark > Building response from a file

+(instancetype)responseWithFileAtPath:(NSString *)filePath
                           statusCode:(int)statusCode
                          requestTime:(NSTimeInterval)requestTime
                         responseTime:(NSTimeInterval)responseTime
                              headers:(NSDictionary *)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithFileAtPath:filePath
                                                          statusCode:statusCode
                                                         requestTime:requestTime
                                                        responseTime:responseTime
                                                             headers:httpHeaders];
    return response;
}


#pragma mark > Building response from HTTP Message Data (dump from "curl -is")

+(instancetype)responseWithHTTPMessageData:(NSData*)responseData
                               requestTime:(NSTimeInterval)requestTime
                              responseTime:(NSTimeInterval)responseTime;
{
    NSData *data = [NSData data];
    NSInteger statusCode = 200;
    NSDictionary *headers = [NSDictionary dictionary];
    
    CFHTTPMessageRef httpMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    if (httpMessage)
    {
        CFHTTPMessageAppendBytes(httpMessage, [responseData bytes], [responseData length]);
        
        data = responseData; // By default
        
        if (CFHTTPMessageIsHeaderComplete(httpMessage))
        {
            statusCode = (NSInteger)CFHTTPMessageGetResponseStatusCode(httpMessage);
            headers = (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(httpMessage);
            data = (__bridge_transfer NSData *)CFHTTPMessageCopyBody(httpMessage);
        }
        CFRelease(httpMessage);
    }
    
    return [self responseWithData:data
                       statusCode:(int)statusCode
                      requestTime:(responseTime<0)?0:responseTime*0.1
                     responseTime:(responseTime<0)?responseTime:responseTime*0.9
                          headers:headers];
}

+(instancetype)responseNamed:(NSString*)responseName
                    inBundle:(NSBundle*)responsesBundle
                 requestTime:(NSTimeInterval)requestTime
                responseTime:(NSTimeInterval)responseTime
{
    NSURL *responseURL = [responsesBundle?:[NSBundle bundleForClass:[self class]] URLForResource:responseName
                                                                                   withExtension:@"response"];
    
    NSData *responseData = [NSData dataWithContentsOfURL:responseURL];
    NSAssert (responseData == nil, @"Could not find HTTP response named '%@' in bundle '%@'", responseName, responsesBundle);
    
    return [self responseWithHTTPMessageData:responseData requestTime:requestTime responseTime:responseTime];
}

#pragma mark > Building an error response

+(instancetype)responseWithError:(NSError*)error
{
    OHHTTPStubsResponse* response = [[self  alloc] initWithError:error];
    return response;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initializers

-(instancetype)initWithInputStream:(NSInputStream*)inputStream
                          dataSize:(unsigned long long)dataSize
                        statusCode:(int)statusCode
                       requestTime:(NSTimeInterval)requestTime
                      responseTime:(NSTimeInterval)responseTime
                           headers:(NSDictionary*)httpHeaders
{
    self = [super init];
    if (self)
    {
        self.inputStream = inputStream;
        self.dataSize = dataSize;
        self.statusCode = statusCode;
        self.requestTime = requestTime;
        self.responseTime = responseTime;
        NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:httpHeaders];
        [headers setObject:[NSString stringWithFormat:@"%llu",self.dataSize] forKey:@"Content-Length"];
        self.httpHeaders = [NSDictionary dictionaryWithDictionary:headers];
    }
    return self;
}

-(instancetype)initWithFileAtPath:(NSString*)filePath
                       statusCode:(int)statusCode
                      requestTime:(NSTimeInterval)requestTime
                     responseTime:(NSTimeInterval)responseTime
                          headers:(NSDictionary*)httpHeaders
{
    NSInputStream* inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    unsigned long long fileSize = [[attributes valueForKey:NSFileSize] unsignedLongLongValue];
    self = [self initWithInputStream:inputStream
                            dataSize:fileSize
                          statusCode:statusCode
                         requestTime:requestTime
                        responseTime:responseTime
                             headers:httpHeaders];
    return self;
}

-(instancetype)initWithData:(NSData*)data
                 statusCode:(int)statusCode
                requestTime:(NSTimeInterval)requestTime
               responseTime:(NSTimeInterval)responseTime
                    headers:(NSDictionary*)httpHeaders
{
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:data];
    self = [self initWithInputStream:inputStream
                            dataSize:[data length]
                          statusCode:statusCode
                         requestTime:requestTime
                        responseTime:responseTime
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


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors

-(void)setRequestTime:(NSTimeInterval)requestTime
{
    NSAssert(requestTime >= 0, @"Invalid Request Time (%f) for OHHTTPStubResponse. Request time must be greater than or equal to zero",requestTime);
    _requestTime = requestTime;
}

// Deprecated
-(NSData*)responseData
{
    NSData* data = nil;
    uint8_t* buffer;
    NSUInteger length;
    if ([self.inputStream getBuffer:&buffer length:&length])
    {
        data = [NSData dataWithBytes:buffer length:length];
    }
    free(buffer);
    return nil;
}

// Deprecated
-(void)setResponseData:(NSData *)responseData
{
    self.inputStream = [NSInputStream inputStreamWithData:responseData];
    self.dataSize = responseData.length;
}

@end
