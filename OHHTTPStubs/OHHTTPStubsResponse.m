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
const NSTimeInterval OHHTTPStubsDefaultRequestTime = 1.0;

const double OHHTTPStubsDownloadSpeedGPRS   =-    56 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeedEDGE   =-   128 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeed3G     =-  3200 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeed3GPlus =-  7200 / 8; // kbps -> KB/s
const double OHHTTPStubsDownloadSpeedWifi   =- 12000 / 8; // kbps -> KB/s

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation OHHTTPStubsResponse

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Setup & Teardown

-(instancetype)initWithInputStream:(NSInputStream*)inputStream
                        statusCode:(int)statusCode
                          dataSize:(unsigned long long)dataSize
                       requestTime:(NSTimeInterval)requestTime 
                      responseTime:(NSTimeInterval)responseTime
                           headers:(NSDictionary*)httpHeaders
{
    self = [super init];
    if(self){
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

-(instancetype)initWithFilePath:(NSString*)filePath
                     statusCode:(int)statusCode
                    requestTime:(NSTimeInterval)requestTime 
                   responseTime:(NSTimeInterval)responseTime
                        headers:(NSDictionary*)httpHeaders{
    NSInputStream* inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    unsigned long long fileSize = [[attributes valueForKey:NSFileSize] unsignedLongLongValue];
    self = [self initWithInputStream:inputStream statusCode:statusCode dataSize:fileSize requestTime:requestTime responseTime:responseTime headers:httpHeaders];
    return self;
}

-(instancetype)initWithData:(NSData*)data
                 statusCode:(int)statusCode
                requestTime:(NSTimeInterval)requestTime 
               responseTime:(NSTimeInterval)responseTime
                    headers:(NSDictionary*)httpHeaders
{
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:data];
    self = [self initWithInputStream:inputStream statusCode:statusCode dataSize:[data length] requestTime:requestTime responseTime:responseTime headers:httpHeaders];
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

-(void)setResponseTime:(NSTimeInterval)responseTime
{
    NSAssert(responseTime!=0, @"Invalid Response Time (%f) for OHHTTPStubResponse. Response time cannot be zero.",responseTime);
    _responseTime = responseTime;
}

-(void)setRequestTime:(NSTimeInterval)requestTime
{
    NSAssert(requestTime >= 0, @"Invalid Request Time (%f) for OHHTTPStubResponse. Request time must be greater than or equal to zero",requestTime);
    _requestTime = requestTime;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class Methods

+(instancetype)responseWithFilePath:(NSString *)filePath
                         statusCode:(int)statusCode
                        requestTime:(NSTimeInterval)requestTime 
                       responseTime:(NSTimeInterval)responseTime
                            headers:(NSDictionary *)httpHeaders
{
    OHHTTPStubsResponse* response = [[self alloc] initWithFilePath:filePath
                                                        statusCode:statusCode
                                                       requestTime:requestTime
                                                      responseTime:responseTime
                                                           headers:httpHeaders];
    return response;
}

+(instancetype)responseWithFilePath:(NSString *)filePath
                        contentType:(NSString*)contentType
                       responseTime:(NSTimeInterval)responseTime
{
    NSDictionary* headers = [NSDictionary dictionaryWithObject:contentType forKey:@"Content-Type"];
    return [self responseWithFilePath:filePath
                           statusCode:200
                          requestTime:OHHTTPStubsDefaultRequestTime
                         responseTime:responseTime
                              headers:headers];
}

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

+(instancetype)responseWithFileInMainBundle:(NSString*)fileName
                                 statusCode:(int)statusCode
                                requestTime:(NSTimeInterval)requestTime
                               responseTime:(NSTimeInterval)responseTime
                                    headers:(NSDictionary*)httpHeaders
{
    NSString* basename = [fileName stringByDeletingPathExtension];
    NSString* extension = [fileName pathExtension];
	NSString* filePath = [[NSBundle bundleForClass:[self class]] pathForResource:basename ofType:extension];
    return [self responseWithFilePath:filePath
                           statusCode:statusCode
                          requestTime:requestTime
                         responseTime:responseTime
                              headers:httpHeaders];
}

+(instancetype)responseWithFileInMainBundle:(NSString*)fileName
                                contentType:(NSString*)contentType
                               responseTime:(NSTimeInterval)responseTime
{
    NSDictionary* headers = [NSDictionary dictionaryWithObject:contentType forKey:@"Content-Type"];
    return [self responseWithFileInMainBundle:fileName
                                   statusCode:200
                                  requestTime:OHHTTPStubsDefaultRequestTime
                                 responseTime:responseTime
                                      headers:headers];
}

+(instancetype)responseWithHTTPMessageData:(NSData*)responseData
                              responseTime:(NSTimeInterval)responseTime;
{
    NSData *data = [NSData data];
    NSInteger statusCode = 200;
    NSDictionary *headers = [NSDictionary dictionary];
    
    CFHTTPMessageRef httpMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    if (httpMessage) {
        CFHTTPMessageAppendBytes(httpMessage, [responseData bytes], [responseData length]);
        
        data = responseData; // By default
        
        if (CFHTTPMessageIsHeaderComplete(httpMessage)) {
            statusCode = (NSInteger)CFHTTPMessageGetResponseStatusCode(httpMessage);
            headers = (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(httpMessage);
            data = (__bridge_transfer NSData *)CFHTTPMessageCopyBody(httpMessage);
        }
        CFRelease(httpMessage);
    }
    
    return [self responseWithData:data statusCode:(int)statusCode requestTime:OHHTTPStubsDefaultRequestTime responseTime:responseTime headers:headers];
}

+(instancetype)responseNamed:(NSString*)responseName
                  fromBundle:(NSBundle*)responsesBundle
                responseTime:(NSTimeInterval)responseTime
{
    if (!responsesBundle) {
        responsesBundle = [NSBundle bundleForClass:[self class]];
    }
    
    NSURL *responseURL = [responsesBundle URLForResource:responseName
                                           withExtension:@"response"];
    
    NSData *responseData = [NSData dataWithContentsOfURL:responseURL];
    
    if (responseData == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Could not find HTTP response named '%@' in bundle '%@'",
                                               responseName, responsesBundle]
                                     userInfo:nil];
    }
    return [self responseWithHTTPMessageData:responseData
                                responseTime:responseTime];
}

+(instancetype)responseWithError:(NSError*)error
{
    OHHTTPStubsResponse* response = [[self  alloc] initWithError:error];
    return response;
}


@end
