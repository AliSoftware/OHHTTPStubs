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
#import "OHHTTPStubsDescriptor.h"
#import "OHHTTPStubsProtocol.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Interfaces

@interface OHHTTPStubs() <OHHTTPStubsManager>

+ (instancetype)sharedInstance;

@property(atomic, strong) id protocolClass;
@property(atomic, copy) NSMutableArray* stubDescriptors;
@property(atomic, assign) BOOL enabledState;
@property(atomic, copy, nullable) void (^onStubActivationBlock)(NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse*);
@property(atomic, copy, nullable) void (^onStubRedirectBlock)(NSURLRequest*, NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse*);
@property(atomic, copy, nullable) void (^afterStubFinishBlock)(NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse*, NSError*);

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
        _protocolClass = [[OHHTTPStubsProtocolClassProxy alloc] initWithManager:self];
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
