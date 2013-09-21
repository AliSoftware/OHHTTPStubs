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

#import "OHHTTPStubs.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Types & Constants

@interface OHHTTPStubsProtocol : NSURLProtocol @end
typedef OHHTTPStubsResponse*(^OHHTTPStubsRequestHandler)(NSURLRequest* request, BOOL onlyCheck);

static NSTimeInterval const kSlotTime = 0.25; // Must be >0. We will send a chunk of the data from the stream each 'slotTime' seconds

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Interface

@interface OHHTTPStubs()
+ (instancetype)sharedInstance;
@property(atomic, strong) NSMutableArray* requestHandlers;
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation OHHTTPStubs

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton methods

+ (instancetype)sharedInstance
{
    static OHHTTPStubs *sharedInstance = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Setup & Teardown

- (id)init
{
    self = [super init];
    if (self)
    {
        _requestHandlers = [NSMutableArray array];
        [self.class setEnabled:YES];
    }
    return self;
}

- (void)dealloc
{
    [self.class setEnabled:NO];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public class methods

+(OHHTTPStubsID)stubRequestsPassingTest:(OHHTTPStubsTestBlock)testBlock
            withStubResponse:(OHHTTPStubsResponseBlock)responseBlock
{
    return [self.sharedInstance addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck)
    {
        BOOL shouldStub = testBlock ? testBlock(request) : YES;
        if (onlyCheck)
        {
            return shouldStub ? (OHHTTPStubsResponse*)@"DummyStub" : (OHHTTPStubsResponse*)nil;
        }
        else
        {
            return (responseBlock && shouldStub) ? responseBlock(request) : nil;
        }
    }];
}

+(BOOL)removeStub:(OHHTTPStubsID)stubID
{
    return [self.sharedInstance removeRequestHandler:stubID];
}
+(void)removeLastStub
{
    [self.sharedInstance removeLastRequestHandler];
}
+(void)removeAllStubs
{
    [self.sharedInstance removeAllRequestHandlers];
}

+(void)setEnabled:(BOOL)enabled
{
    static BOOL currentEnabledState = NO;
    if (enabled && !currentEnabledState)
    {
        [NSURLProtocol registerClass:OHHTTPStubsProtocol.class];
    }
    else if (!enabled && currentEnabledState)
    {
        // Force instanciate sharedInstance to avoid it being created later and this turning setEnabled to YES again
        (void)self.sharedInstance; // This way if we call [setEnabled:NO] before any call to sharedInstance it will be kept disabled
        [NSURLProtocol unregisterClass:OHHTTPStubsProtocol.class];
    }
    currentEnabledState = enabled;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private instance methods

-(OHHTTPStubsID)addRequestHandler:(OHHTTPStubsRequestHandler)handler
{
    OHHTTPStubsRequestHandler handlerCopy = [handler copy];
    @synchronized(_requestHandlers)
    {
        [_requestHandlers addObject:handlerCopy];
    }
    return handlerCopy;
}

-(BOOL)removeRequestHandler:(OHHTTPStubsID)stubID
{
    BOOL handlerFound = NO;
    @synchronized(_requestHandlers)
    {
        handlerFound = [self.requestHandlers containsObject:stubID];
        [_requestHandlers removeObject:stubID];
    }
    return handlerFound;
}
-(void)removeLastRequestHandler
{
    @synchronized(_requestHandlers)
    {
        [_requestHandlers removeLastObject];
    }
}

-(void)removeAllRequestHandlers
{
    @synchronized(_requestHandlers)
    {
        [_requestHandlers removeAllObjects];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods

- (OHHTTPStubsResponse*)responseForRequest:(NSURLRequest*)request onlyCheck:(BOOL)onlyCheck
{
    OHHTTPStubsResponse* response = nil;
    @synchronized(_requestHandlers)
    {
        for(OHHTTPStubsRequestHandler handler in _requestHandlers.reverseObjectEnumerator)
        {
            response = handler(request, onlyCheck);
            if (response) break;
        }
    }
    return response;
}

@end




////////////////////////////////////////////////////////////////////////////////
#pragma mark - Deprecated Methods (will be removed in 3.0)
/*! @name Deprecated Methods */

@implementation OHHTTPStubs (Deprecated)

+(OHHTTPStubsRequestHandlerID)addRequestHandler:(OHHTTPStubsRequestHandler)handler
{
    return [self.sharedInstance addRequestHandler:handler];
}

+(BOOL)removeRequestHandler:(OHHTTPStubsRequestHandlerID)handler
{
    return [self removeStub:handler];
}

+(void)removeLastRequestHandler
{
    return [self removeLastStub];
}

+(void)removeAllRequestHandlers
{
    return [self removeAllStubs];
}

@end







////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Protocol Class

@interface OHHTTPStubsProtocol()
@property(nonatomic, assign) BOOL stopped;
@end

@implementation OHHTTPStubsProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return ([OHHTTPStubs.sharedInstance responseForRequest:request onlyCheck:YES] != nil);
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)response client:(id<NSURLProtocolClient>)client
{
    // Make super sure that we never use a cached response.
    return [super initWithRequest:request cachedResponse:nil client:client];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
	return request;
}

- (NSCachedURLResponse *)cachedResponse
{
	return nil;
}

- (void)startLoading
{
    NSURLRequest* request = self.request;
	id<NSURLProtocolClient> client = self.client;
    
    OHHTTPStubsResponse* responseStub = [OHHTTPStubs.sharedInstance responseForRequest:request onlyCheck:NO];
    
    if (responseStub.error == nil)
    {        
        NSHTTPURLResponse* urlResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                     statusCode:responseStub.statusCode
                                                                    HTTPVersion:@"HTTP/1.1"
                                                                   headerFields:responseStub.httpHeaders];
        
        // Cookies handling
        if (request.HTTPShouldHandleCookies)
        {
            NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:responseStub.httpHeaders forURL:request.URL];
            [NSHTTPCookieStorage.sharedHTTPCookieStorage setCookies:cookies forURL:request.URL mainDocumentURL:request.mainDocumentURL];
        }
        
        
        NSString* redirectLocation = (responseStub.httpHeaders)[@"Location"];
        NSURL* redirectLocationURL;
        if (redirectLocation)
        {
            redirectLocationURL = [NSURL URLWithString:redirectLocation];
        }
        else
        {
            redirectLocationURL = nil;
        }
        if (((responseStub.statusCode >= 300) && (responseStub.statusCode < 400)) && redirectLocationURL)
        {
            NSURLRequest* redirectRequest = [NSURLRequest requestWithURL:redirectLocationURL];
            execute_after(responseStub.requestTime, ^{
                if (!self.stopped)
                {
                    [client URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:urlResponse];
                }
            });
        }
        else
        {
            execute_after(responseStub.requestTime,^{
                if (!self.stopped)
                {
                    [client URLProtocol:self didReceiveResponse:urlResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                    if(responseStub.inputStream.streamStatus == NSStreamStatusNotOpen)
                    {
                        [responseStub.inputStream open];
                    }
                    [self streamDataForClient:client
                             withStubResponse:responseStub
                                   completion:^(NSError * error)
                     {
                         [responseStub.inputStream close];
                         if (error==nil)
                         {
                             [client URLProtocolDidFinishLoading:self];
                         }
                         else
                         {
                             [client URLProtocol:self didFailWithError:responseStub.error];
                         }
                     }];
                }
            });
        }
    } else {
        // Send the canned error
        execute_after(responseStub.responseTime, ^{
            if (!self.stopped)
            {
                [client URLProtocol:self didFailWithError:responseStub.error];
            }
        });
    }
}

- (void)stopLoading
{
    self.stopped = YES;
}

typedef struct {
    NSTimeInterval slotTime;
    double chunkSizePerSlot;
    double cumulativeChunkSize;
} OHHTTPStubsStreamTimingInfo;

- (void)streamDataForClient:(id<NSURLProtocolClient>)client
           withStubResponse:(OHHTTPStubsResponse*)stubResponse
                 completion:(void(^)(NSError * error))completion
{
    if (stubResponse.inputStream.hasBytesAvailable && !self.stopped)
    {
        // Compute timing data once and for all for this stub
        
        OHHTTPStubsStreamTimingInfo timingInfo = {
            .slotTime = kSlotTime, // Must be >0. We will send a chunk of data from the stream each 'slotTime' seconds
            .cumulativeChunkSize = 0
        };
        
        if(stubResponse.responseTime < 0)
        {
            // Bytes send each 'slotTime' seconds = Speed in KB/s * 1000 * slotTime in seconds
            timingInfo.chunkSizePerSlot = (fabs(stubResponse.responseTime) * 1000) * timingInfo.slotTime;
        }
        else if (stubResponse.responseTime < kSlotTime) // includes case when responseTime == 0
        {
            // We want to send the whole data quicker than the slotTime, so send it all in one chunk.
            timingInfo.chunkSizePerSlot = stubResponse.dataSize;
            timingInfo.slotTime = stubResponse.responseTime;
        }
        else
        {
            // Bytes send each 'slotTime' seconds = (Whole size in bytes / response time) * slotTime = speed in bps * slotTime in seconds
            timingInfo.chunkSizePerSlot = ((stubResponse.dataSize/stubResponse.responseTime) * timingInfo.slotTime);
        }
        
        [self streamDataForClient:client
                       fromStream:stubResponse.inputStream
                       timingInfo:timingInfo
                       completion:completion];
    }
    else
    {
        if (completion)
        {
            completion(nil);
        }
    }
}

- (void) streamDataForClient:(id<NSURLProtocolClient>)client
                  fromStream:(NSInputStream*)inputStream
                  timingInfo:(OHHTTPStubsStreamTimingInfo)timingInfo
                  completion:(void(^)(NSError * error))completion
{
    NSParameterAssert(timingInfo.chunkSizePerSlot > 0);
    
    if (inputStream.hasBytesAvailable && !self.stopped)
    {
        // This is needed in case we computed a non-integer chunkSizePerSlot, to avoid cumulative errors
        double cumulativeChunkSizeAfterRead = timingInfo.cumulativeChunkSize + timingInfo.chunkSizePerSlot;
        NSUInteger chunkSizeToRead = floor(cumulativeChunkSizeAfterRead) - floor(timingInfo.cumulativeChunkSize);
        timingInfo.cumulativeChunkSize = cumulativeChunkSizeAfterRead;
        
        if (chunkSizeToRead == 0)
        {
            // Nothing to read at this pass, but probably later
            execute_after(timingInfo.slotTime, ^{
                [self streamDataForClient:client fromStream:inputStream
                               timingInfo:timingInfo completion:completion];
            });
        } else {
            uint8_t buffer[chunkSizeToRead];
            NSInteger bytesRead = [inputStream read:buffer maxLength:chunkSizeToRead];
            if (bytesRead > 0)
            {
                NSData * data = [NSData dataWithBytes:buffer length:bytesRead];
                // Wait for 'slotTime' seconds before sending the chunk.
                // If bytesRead < chunkSizePerSlot (because we are near the EOF), adjust slotTime proportionally to the bytes remaining
                execute_after(((double)bytesRead / (double)chunkSizeToRead) * timingInfo.slotTime, ^{
                    [client URLProtocol:self didLoadData:data];
                    [self streamDataForClient:client fromStream:inputStream
                                   timingInfo:timingInfo completion:completion];
                });
            }
            else
            {
                if (completion)
                {
                    // Note: We may also arrive here with no error if we were just at the end of the stream (EOF)
                    // In that case, hasBytesAvailable did return YES (because at the limit of OEF) but nothing were read (because EOF)
                    // But then in that case inputStream.streamError will be nil so that's cool, we won't return an error anyway
                    completion(inputStream.streamError);
                }
            }
        }
    }
    else
    {
        if (completion)
        {
            completion(nil);
        }
    }
}

/////////////////////////////////////////////
// Delayed execution utility methods
/////////////////////////////////////////////

void execute_after(NSTimeInterval delayInSeconds, dispatch_block_t block)
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

@end
