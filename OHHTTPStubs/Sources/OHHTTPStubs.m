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

static NSTimeInterval const kSlotTime = 0.25; // Must be >0. We will send a chunk of the data from the stream each 'slotTime' seconds

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Interfaces

@interface OHHTTPStubs()
+ (instancetype)sharedInstance;
@property(atomic, copy) NSMutableArray* stubDescriptors;
@property(atomic, copy) void (^onStubActivationBlock)(NSURLRequest*, id<OHHTTPStubsDescriptor>);
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
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Setup & Teardown

extern void _OHHTTPStubs_InstallNSURLSessionConfigurationMagicSupport();

+ (void)initialize
{
    if (self == [OHHTTPStubs class])
    {
        [self setEnabled:YES];
        _OHHTTPStubs_InstallNSURLSessionConfigurationMagicSupport();
    }
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _stubDescriptors = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    [self.class setEnabled:NO];
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
+(void)removeLastStub
{
    [OHHTTPStubs.sharedInstance removeLastStub];
}
+(void)removeAllStubs
{
    [OHHTTPStubs.sharedInstance removeAllStubs];
}

#pragma mark > Disabling & Re-Enabling stubs

+(void)setEnabled:(BOOL)enable
{
    static BOOL currentEnabledState = NO;
    if (enable && !currentEnabledState)
    {
        [NSURLProtocol registerClass:OHHTTPStubsProtocol.class];
    }
    else if (!enable && currentEnabledState)
    {
        [NSURLProtocol unregisterClass:OHHTTPStubsProtocol.class];
    }
    currentEnabledState = enable;
}

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) \
 || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
+ (void)setEnabled:(BOOL)enable forSessionConfiguration:(NSURLSessionConfiguration*)sessionConfig
{
    // Runtime check to make sure the API is available on this version
    if (   [sessionConfig respondsToSelector:@selector(protocolClasses)]
        && [sessionConfig respondsToSelector:@selector(setProtocolClasses:)])
    {
        NSMutableArray * urlProtocolClasses = [NSMutableArray arrayWithArray:sessionConfig.protocolClasses];
        Class protoCls = OHHTTPStubsProtocol.class;
        if (enable && ![urlProtocolClasses containsObject:protoCls])
        {
            [urlProtocolClasses addObject:protoCls];
        }
        else if (!enable  && [urlProtocolClasses containsObject:protoCls])
        {
            [urlProtocolClasses removeObject:protoCls];
        }
        sessionConfig.protocolClasses = urlProtocolClasses;
    }
    else
    {
        NSLog(@"[OHHTTPStubs] %@ is only available when running on iOS7+. Use conditions like 'if ([NSURLSessionConfiguration class])' to only call this method if the user is running iOS7+.", NSStringFromSelector(_cmd));
    }
}
#endif

#pragma mark > Debug Methods

+(NSArray*)allStubs
{
    return [OHHTTPStubs.sharedInstance stubDescriptors];
}

+(void)onStubActivation:( void(^)(NSURLRequest* request, id<OHHTTPStubsDescriptor> stub) )block
{
    [OHHTTPStubs.sharedInstance setOnStubActivationBlock:block];
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private instance methods

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

-(void)removeLastStub
{
    @synchronized(_stubDescriptors)
    {
        [_stubDescriptors removeLastObject];
    }
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

@interface OHHTTPStubsProtocol()
@property(nonatomic, assign) BOOL stopped;
@end

@implementation OHHTTPStubsProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return ([OHHTTPStubs.sharedInstance firstStubPassingTestForRequest:request] != nil);
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
    
    OHHTTPStubsDescriptor* stub = [OHHTTPStubs.sharedInstance firstStubPassingTestForRequest:request];
    NSAssert(stub, @"At the time startLoading is called, canInitRequest should have assured that stub is != nil beforehand");
    OHHTTPStubsResponse* responseStub = stub.responseBlock(request);

    if (OHHTTPStubs.sharedInstance.onStubActivationBlock)
    {
        OHHTTPStubs.sharedInstance.onStubActivationBlock(request, stub);
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

static void execute_after(NSTimeInterval delayInSeconds, dispatch_block_t block)
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

@end
