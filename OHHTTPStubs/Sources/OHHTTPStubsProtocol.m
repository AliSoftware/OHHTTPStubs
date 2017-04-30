//
//  OHHTTPStubsProtocol.m
//  OHHTTPStubs
//
//  Created by Nickolas Pohilets on 29.04.17.
//  Copyright © 2017 AliSoftware. All rights reserved.
//

#import "OHHTTPStubsProtocol.h"
#import <objc/runtime.h>

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Types & Constants

static NSTimeInterval const kSlotTime = 0.25; // Must be >0. We will send a chunk of the data from the stream each 'slotTime' seconds

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Proxies

@implementation OHHTTPStubsProtocolClassProxy
{
    OHHTTPStubsProtocolInstanceProxy *_instance;
}

- (instancetype)initWithManager:(id<OHHTTPStubsManager>)manager {
    _instance = [[OHHTTPStubsProtocolInstanceProxy alloc] initWithManager:manager];
    return self;
}

- (Class)superclass {
    return [OHHTTPStubsProtocol superclass];
}

- (Class)class {
    return (id)self;
}

- (BOOL)isSubclassOfClass:(Class)klass {
    return [OHHTTPStubsProtocol isSubclassOfClass:klass];
}

- (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return ([_instance.manager firstStubPassingTestForRequest:request] != nil);
}

- (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (id)alloc NS_RETURNS_RETAINED {
    return _instance;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [OHHTTPStubsProtocol respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [OHHTTPStubsProtocol methodSignatureForSelector:sel];
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    // This copies some NSURLSessionTask-related methods from NSURLProtocol.
    // Their default implementation forwards to methds that accept NSURLRequest.
    Method m = class_getClassMethod(OHHTTPStubsProtocol.self, sel);
    if (!m) {
        return NO;
    }
    class_addMethod(self, sel, method_getImplementation(m), method_getTypeEncoding(m));
    return YES;
}

@end

@implementation OHHTTPStubsProtocolInstanceProxy

- (instancetype)initWithManager:(id<OHHTTPStubsManager>)manager {
    _manager = manager;
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)response client:(id<NSURLProtocolClient>)client {
    return (id)[[OHHTTPStubsProtocol alloc] initWithManager:_manager request:request cachedResponse:response client:client];
}

- (Class)class {
    // Proper implementation probably should return a parent instance of OHHTTPStubsProtocolClassProxy
    // But this method is not called, so let's avoid writing dead code.
    NSAssert(NO, @"-[OHHTTPStubsProtocolInstanceProxy class] is not implemented");
    return [OHHTTPStubsProtocol class];
}

- (Class)superclass {
    return [OHHTTPStubsProtocol superclass];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [OHHTTPStubsProtocol instancesRespondToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [OHHTTPStubsProtocol instanceMethodSignatureForSelector:sel];
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    // This copies some NSURLSessionTask-related methods from NSURLProtocol.
    // Their default implementation forwards to methds that accept NSURLRequest.
    Method m = class_getInstanceMethod(OHHTTPStubsProtocol.self, sel);
    if (!m) {
        return NO;
    }
    
    class_addMethod(self, sel, method_getImplementation(m), method_getTypeEncoding(m));
    return YES;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Protocol

@interface OHHTTPStubsProtocol()
@property(assign) BOOL stopped;
@property(strong) id<OHHTTPStubsManager> manager;
@property(strong) OHHTTPStubsDescriptor* stub;
@property(assign) CFRunLoopRef clientRunLoop;
- (void)executeOnClientRunLoopAfterDelay:(NSTimeInterval)delayInSeconds block:(dispatch_block_t)block;
@end

@implementation OHHTTPStubsProtocol

- (id)initWithManager:(id<OHHTTPStubsManager>)manager
              request:(NSURLRequest *)request
       cachedResponse:(NSCachedURLResponse *)response
               client:(id<NSURLProtocolClient>)client
{
    NSParameterAssert(manager);
    
    // Make super sure that we never use a cached response.
    self = [super initWithRequest:request cachedResponse:nil client:client];
    if (self) {
        self.manager = manager;
        self.stub = [manager firstStubPassingTestForRequest:self.request];
    }
    return self;
}

- (NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void)startLoading
{
    self.clientRunLoop = CFRunLoopGetCurrent();
    NSURLRequest* request = self.request;
    id<NSURLProtocolClient> client = self.client;
    
    if (!self.stub)
    {
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"It seems like the stub has been removed BEFORE the response had time to be sent.",
                                  NSLocalizedFailureReasonErrorKey,
                                  @"For more info, see https://github.com/AliSoftware/OHHTTPStubs/wiki/OHHTTPStubs-and-asynchronous-tests",
                                  NSLocalizedRecoverySuggestionErrorKey,
                                  request.URL, // Stop right here if request.URL is nil
                                  NSURLErrorFailingURLErrorKey,
                                  nil];
        NSError* error = [NSError errorWithDomain:@"OHHTTPStubs" code:500 userInfo:userInfo];
        [client URLProtocol:self didFailWithError:error];
        if (self.manager.afterStubFinishBlock)
        {
            self.manager.afterStubFinishBlock(request, self.stub, nil, error);
        }
        return;
    }
    
    OHHTTPStubsResponse* responseStub = self.stub.responseBlock(request);
    
    if (self.manager.onStubActivationBlock)
    {
        self.manager.onStubActivationBlock(request, self.stub, responseStub);
    }
    
    if (responseStub.error == nil)
    {
        NSHTTPURLResponse* urlResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                     statusCode:responseStub.statusCode
                                                                    HTTPVersion:@"HTTP/1.1"
                                                                   headerFields:responseStub.httpHeaders];
        
        // Cookies handling
        if (request.HTTPShouldHandleCookies && request.URL)
        {
            NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:responseStub.httpHeaders forURL:request.URL];
            if (cookies)
            {
                [NSHTTPCookieStorage.sharedHTTPCookieStorage setCookies:cookies forURL:request.URL mainDocumentURL:request.mainDocumentURL];
            }
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
        [self executeOnClientRunLoopAfterDelay:responseStub.requestTime block:^{
            if (!self.stopped)
            {
                // Notify if a redirection occurred
                if (((responseStub.statusCode > 300) && (responseStub.statusCode < 400)) && redirectLocationURL)
                {
                    NSURLRequest* redirectRequest = [NSURLRequest requestWithURL:redirectLocationURL];
                    [client URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:urlResponse];
                    if (self.manager.onStubRedirectBlock)
                    {
                        self.manager.onStubRedirectBlock(request, redirectRequest, self.stub, responseStub);
                    }
                }
                
                // Send the response (even for redirections)
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
                     NSError *blockError = nil;
                     if (error==nil)
                     {
                         [client URLProtocolDidFinishLoading:self];
                     }
                     else
                     {
                         [client URLProtocol:self didFailWithError:responseStub.error];
                         blockError = responseStub.error;
                     }
                     if (self.manager.afterStubFinishBlock)
                     {
                         self.manager.afterStubFinishBlock(request, self.stub, responseStub, blockError);
                     }
                 }];
            }
        }];
    } else {
        // Send the canned error
        [self executeOnClientRunLoopAfterDelay:responseStub.responseTime block:^{
            if (!self.stopped)
            {
                [client URLProtocol:self didFailWithError:responseStub.error];
                if (self.manager.afterStubFinishBlock)
                {
                    self.manager.afterStubFinishBlock(request, self.stub, responseStub, responseStub.error);
                }
            }
        }];
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
    if (!self.stopped)
    {
        if ((stubResponse.dataSize>0) && stubResponse.inputStream.hasBytesAvailable)
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
            [self executeOnClientRunLoopAfterDelay:stubResponse.responseTime block:^{
                if (completion && !self.stopped)
                {
                    completion(nil);
                }
            }];
        }
    }
}

- (void) streamDataForClient:(id<NSURLProtocolClient>)client
                  fromStream:(NSInputStream*)inputStream
                  timingInfo:(OHHTTPStubsStreamTimingInfo)timingInfo
                  completion:(void(^)(NSError * error))completion
{
    NSParameterAssert(timingInfo.chunkSizePerSlot > 0);
    
    if (inputStream.hasBytesAvailable && (!self.stopped))
    {
        // This is needed in case we computed a non-integer chunkSizePerSlot, to avoid cumulative errors
        double cumulativeChunkSizeAfterRead = timingInfo.cumulativeChunkSize + timingInfo.chunkSizePerSlot;
        NSUInteger chunkSizeToRead = floor(cumulativeChunkSizeAfterRead) - floor(timingInfo.cumulativeChunkSize);
        timingInfo.cumulativeChunkSize = cumulativeChunkSizeAfterRead;
        
        if (chunkSizeToRead == 0)
        {
            // Nothing to read at this pass, but probably later
            [self executeOnClientRunLoopAfterDelay:timingInfo.slotTime block:^{
                [self streamDataForClient:client fromStream:inputStream
                               timingInfo:timingInfo completion:completion];
            }];
        } else {
            uint8_t* buffer = (uint8_t*)malloc(sizeof(uint8_t)*chunkSizeToRead);
            NSInteger bytesRead = [inputStream read:buffer maxLength:chunkSizeToRead];
            if (bytesRead > 0)
            {
                NSData * data = [NSData dataWithBytes:buffer length:bytesRead];
                // Wait for 'slotTime' seconds before sending the chunk.
                // If bytesRead < chunkSizePerSlot (because we are near the EOF), adjust slotTime proportionally to the bytes remaining
                [self executeOnClientRunLoopAfterDelay:((double)bytesRead / (double)chunkSizeToRead) * timingInfo.slotTime block:^{
                    [client URLProtocol:self didLoadData:data];
                    [self streamDataForClient:client fromStream:inputStream
                                   timingInfo:timingInfo completion:completion];
                }];
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
            free(buffer);
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

- (void)executeOnClientRunLoopAfterDelay:(NSTimeInterval)delayInSeconds block:(dispatch_block_t)block
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFRunLoopPerformBlock(self.clientRunLoop, kCFRunLoopDefaultMode, block);
        CFRunLoopWakeUp(self.clientRunLoop);
    });
}

@end
