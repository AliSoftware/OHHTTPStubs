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
#import <objc/runtime.h>

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Types & Constants

@interface OHHTTPStubsProtocolClassProxy : NSProxy

- (instancetype)initWithStubs:(OHHTTPStubs*)stubs;

@end

@interface OHHTTPStubsProtocolInstanceProxy : NSProxy

- (instancetype)initWithStubs:(OHHTTPStubs *)stubs;

@property(atomic, weak, readonly) OHHTTPStubs* stubs;

@end

@interface OHHTTPStubsProtocol : NSURLProtocol

- (id)initWithStubs:(OHHTTPStubs *)stubs
            request:(NSURLRequest *)request
     cachedResponse:(NSCachedURLResponse *)response
             client:(id<NSURLProtocolClient>)client;

@end

static NSTimeInterval const kSlotTime = 0.25; // Must be >0. We will send a chunk of the data from the stream each 'slotTime' seconds

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Interfaces

@interface OHHTTPStubs()
+ (instancetype)sharedInstance;
@property(atomic, strong) id protocolClass;
@property(atomic, copy) NSMutableArray* stubDescriptors;
@property(atomic, assign) BOOL enabledState;
@property(atomic, copy, nullable) void (^onStubActivationBlock)(NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse*);
@property(atomic, copy, nullable) void (^onStubRedirectBlock)(NSURLRequest*, NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse*);
@property(atomic, copy, nullable) void (^afterStubFinishBlock)(NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse*, NSError*);
@end

@interface OHHTTPStubsDescriptor : NSObject <OHHTTPStubsDescriptor>
@property(atomic, copy) OHHTTPStubsTestBlock testBlock;
@property(atomic, copy) OHHTTPStubsResponseBlock responseBlock;
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - OHHTTPStubsDescriptor Implementation

@implementation OHHTTPStubsDescriptor

@synthesize name = _name;

+(instancetype)stubDescriptorWithTestBlock:(OHHTTPStubsTestBlock)testBlock
                             responseBlock:(OHHTTPStubsResponseBlock)responseBlock
{
    OHHTTPStubsDescriptor* stub = [OHHTTPStubsDescriptor new];
    stub.testBlock = testBlock;
    stub.responseBlock = responseBlock;
    return stub;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@ %p : %@>", self.class, self, self.name];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - OHHTTPStubs Implementation

@implementation OHHTTPStubs

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton methods

+ (instancetype)sharedInstance
{
    static OHHTTPStubs *sharedInstance = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] initEnabled:YES];
    });
    return sharedInstance;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Setup & Teardown

- (instancetype)initEnabled:(BOOL)enabled
{
    self = [super init];
    if (self)
    {
        _stubDescriptors = [NSMutableArray array];
        _protocolClass = [[OHHTTPStubsProtocolClassProxy alloc] initWithStubs:self];
        _enabledState = enabled;
        if (enabled) {
            [self _setEnable:YES];
        }
    }
    return self;
}

- (void)dealloc
{
    if (_enabledState) {
        [self _setEnable:NO];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public class methods

#pragma mark > Adding & Removing stubs

+(id<OHHTTPStubsDescriptor>)stubRequestsPassingTest:(OHHTTPStubsTestBlock)testBlock
                                   withStubResponse:(OHHTTPStubsResponseBlock)responseBlock
{
    OHHTTPStubsDescriptor* stub = [OHHTTPStubsDescriptor stubDescriptorWithTestBlock:testBlock
                                                                       responseBlock:responseBlock];
    [OHHTTPStubs.sharedInstance addStub:stub];
    return stub;
}

+(BOOL)removeStub:(id<OHHTTPStubsDescriptor>)stubDesc
{
    return [OHHTTPStubs.sharedInstance removeStub:stubDesc];
}

+(void)removeAllStubs
{
    [OHHTTPStubs.sharedInstance removeAllStubs];
}

#pragma mark > Disabling & Re-Enabling stubs

+(void)setEnabled:(BOOL)enabled
{
    [OHHTTPStubs.sharedInstance setEnabled:enabled];
}

+(BOOL)isEnabled
{
    return OHHTTPStubs.sharedInstance.isEnabled;
}

#if defined(__IPHONE_7_0) || defined(__MAC_10_9)
+ (void)setEnabled:(BOOL)enable forSessionConfiguration:(NSURLSessionConfiguration*)sessionConfig
{
    [OHHTTPStubs.sharedInstance setEnabled:enable forSessionConfiguration:sessionConfig];
}

+ (BOOL)isEnabledForSessionConfiguration:(NSURLSessionConfiguration *)sessionConfig
{
    return [OHHTTPStubs.sharedInstance isEnabledForSessionConfiguration:sessionConfig];
}
#endif

#pragma mark > Debug Methods

+(NSArray*)allStubs
{
    return [OHHTTPStubs.sharedInstance stubDescriptors];
}

+(void)onStubActivation:( nullable void(^)(NSURLRequest* request, id<OHHTTPStubsDescriptor> stub, OHHTTPStubsResponse* responseStub) )block
{
    [OHHTTPStubs.sharedInstance setOnStubActivationBlock:block];
}

+(void)onStubRedirectResponse:( nullable void(^)(NSURLRequest* request, NSURLRequest* redirectRequest, id<OHHTTPStubsDescriptor> stub, OHHTTPStubsResponse* responseStub) )block
{
    [OHHTTPStubs.sharedInstance setOnStubRedirectBlock:block];
}

+(void)afterStubFinish:( nullable void(^)(NSURLRequest* request, id<OHHTTPStubsDescriptor> stub, OHHTTPStubsResponse* responseStub, NSError* error) )block
{
    [OHHTTPStubs.sharedInstance setAfterStubFinishBlock:block];
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private instance methods

-(BOOL)isEnabled
{
    BOOL enabled = NO;
    @synchronized(self)
    {
        enabled = _enabledState;
    }
    return enabled;
}

-(void)setEnabled:(BOOL)enable
{
    @synchronized(self)
    {
        _enabledState = enable;
        [self _setEnable:_enabledState];
    }
}

-(void)_setEnable:(BOOL)enable
{
    if (enable)
    {
        [NSURLProtocol registerClass:[self protocolClass]];
    }
    else
    {
        [NSURLProtocol unregisterClass:[self protocolClass]];
    }
}

#if defined(__IPHONE_7_0) || defined(__MAC_10_9)
- (void)setEnabled:(BOOL)enable forSessionConfiguration:(NSURLSessionConfiguration*)sessionConfig
{
    // Runtime check to make sure the API is available on this version
    if (   [sessionConfig respondsToSelector:@selector(protocolClasses)]
        && [sessionConfig respondsToSelector:@selector(setProtocolClasses:)])
    {
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray:sessionConfig.protocolClasses];
        id protoCls = [self protocolClass];
        if (enable && ![urlProtocolClasses containsObject:protoCls])
        {
            [urlProtocolClasses insertObject:protoCls atIndex:0];
        }
        else if (!enable && [urlProtocolClasses containsObject:protoCls])
        {
            [urlProtocolClasses removeObject:protoCls];
        }
        sessionConfig.protocolClasses = urlProtocolClasses;
    }
    else
    {
        NSLog(@"[OHHTTPStubs] %@ is only available when running on iOS7+/OSX9+. "
              @"Use conditions like 'if ([NSURLSessionConfiguration class])' to only call "
              @"this method if the user is running iOS7+/OSX9+.", NSStringFromSelector(_cmd));
    }
}

- (BOOL)isEnabledForSessionConfiguration:(NSURLSessionConfiguration *)sessionConfig
{
    // Runtime check to make sure the API is available on this version
    if (   [sessionConfig respondsToSelector:@selector(protocolClasses)]
        && [sessionConfig respondsToSelector:@selector(setProtocolClasses:)])
    {
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray:sessionConfig.protocolClasses];
        id protoCls = [self protocolClass];
        return [urlProtocolClasses containsObject:protoCls];
    }
    else
    {
        NSLog(@"[OHHTTPStubs] %@ is only available when running on iOS7+/OSX9+. "
              @"Use conditions like 'if ([NSURLSessionConfiguration class])' to only call "
              @"this method if the user is running iOS7+/OSX9+.", NSStringFromSelector(_cmd));
        return NO;
    }
}
#endif

-(void)addStub:(OHHTTPStubsDescriptor*)stubDesc
{
    @synchronized(_stubDescriptors)
    {
        [_stubDescriptors addObject:stubDesc];
    }
}

-(BOOL)removeStub:(id<OHHTTPStubsDescriptor>)stubDesc
{
    BOOL handlerFound = NO;
    @synchronized(_stubDescriptors)
    {
        handlerFound = [_stubDescriptors containsObject:stubDesc];
        [_stubDescriptors removeObject:stubDesc];
    }
    return handlerFound;
}

-(void)removeAllStubs
{
    @synchronized(_stubDescriptors)
    {
        [_stubDescriptors removeAllObjects];
    }
}

- (OHHTTPStubsDescriptor*)firstStubPassingTestForRequest:(NSURLRequest*)request
{
    OHHTTPStubsDescriptor* foundStub = nil;
    @synchronized(_stubDescriptors)
    {
        for(OHHTTPStubsDescriptor* stub in _stubDescriptors.reverseObjectEnumerator)
        {
            if (stub.testBlock(request))
            {
                foundStub = stub;
                break;
            }
        }
    }
    return foundStub;
}

@end










////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Protocol Class

@interface NSURLProtocol()

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request task:(NSURLSessionTask*)task;

@end

@implementation OHHTTPStubsProtocolClassProxy
{
    OHHTTPStubsProtocolInstanceProxy *_instance;
}

- (instancetype)initWithStubs:(OHHTTPStubs *)stubs {
    _instance = [[OHHTTPStubsProtocolInstanceProxy alloc] initWithStubs:stubs];
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
    return ([_instance.stubs firstStubPassingTestForRequest:request] != nil);
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
    Method m = class_getClassMethod(OHHTTPStubsProtocol.self, sel);
    if (!m) {
        return NO;
    }
    class_addMethod(self, sel, method_getImplementation(m), method_getTypeEncoding(m));
    return YES;
}

@end

@implementation OHHTTPStubsProtocolInstanceProxy

- (instancetype)initWithStubs:(OHHTTPStubs *)stubs {
    _stubs = stubs;
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)response client:(id<NSURLProtocolClient>)client {
    return (id)[[OHHTTPStubsProtocol alloc] initWithStubs:_stubs request:request cachedResponse:response client:client];
}

- (Class)class {
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
    Method m = class_getInstanceMethod(OHHTTPStubsProtocol.self, sel);
    if (!m) {
        return NO;
    }
    
    class_addMethod(self, sel, method_getImplementation(m), method_getTypeEncoding(m));
    return YES;
}

@end


@interface OHHTTPStubsProtocol()
@property(assign) BOOL stopped;
@property(strong) OHHTTPStubs* stubs;
@property(strong) OHHTTPStubsDescriptor* stub;
@property(assign) CFRunLoopRef clientRunLoop;
- (void)executeOnClientRunLoopAfterDelay:(NSTimeInterval)delayInSeconds block:(dispatch_block_t)block;
@end

@implementation OHHTTPStubsProtocol
{
    OHHTTPStubs *_stubs;
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task {
    return [super canInitWithTask:task];
}

- (id)initWithStubs:(OHHTTPStubs *)stubs
            request:(NSURLRequest *)request
     cachedResponse:(NSCachedURLResponse *)response
             client:(id<NSURLProtocolClient>)client
{
    NSParameterAssert(stubs);
    
    // Make super sure that we never use a cached response.
    self = [super initWithRequest:request cachedResponse:nil client:client];
    if (self) {
        self.stubs = stubs;
        self.stub = [stubs firstStubPassingTestForRequest:self.request];
    }
    return self;
}

- (id)initWithStubs:(OHHTTPStubs *)stubs
               task:(NSURLSessionTask *)task
     cachedResponse:(NSCachedURLResponse *)cachedResponse
             client:(id<NSURLProtocolClient>)client
{
    // Make super sure that we never use a cached response.
    self = [super initWithTask:task cachedResponse:nil client:client];
    if (self) {
        self.stubs = stubs;
        self.stub = [stubs firstStubPassingTestForRequest:self.request];
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
        if (self.stubs.afterStubFinishBlock)
        {
            self.stubs.afterStubFinishBlock(request, self.stub, nil, error);
        }
        return;
    }
    
    OHHTTPStubsResponse* responseStub = self.stub.responseBlock(request);
    
    if (self.stubs.onStubActivationBlock)
    {
        self.stubs.onStubActivationBlock(request, self.stub, responseStub);
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
                    if (self.stubs.onStubRedirectBlock)
                    {
                        self.stubs.onStubRedirectBlock(request, redirectRequest, self.stub, responseStub);
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
                     if (self.stubs.afterStubFinishBlock)
                     {
                         self.stubs.afterStubFinishBlock(request, self.stub, responseStub, blockError);
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
                if (self.stubs.afterStubFinishBlock)
                {
                    self.stubs.afterStubFinishBlock(request, self.stub, responseStub, responseStub.error);
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
