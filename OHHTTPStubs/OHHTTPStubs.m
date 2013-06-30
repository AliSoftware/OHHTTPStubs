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
#pragma mark - Types

@interface OHHTTPStubsProtocol : NSURLProtocol @end
typedef OHHTTPStubsResponse*(^OHHTTPStubsRequestHandler)(NSURLRequest* request, BOOL onlyCheck);

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Interface

@interface OHHTTPStubs()
-(id)addRequestHandler:(OHHTTPStubsRequestHandler)handler;
-(BOOL)removeRequestHandler:(id)handler;
-(void)removeLastRequestHandler;
-(void)removeAllRequestHandlers;
@property(nonatomic, strong) NSMutableArray* requestHandlers;
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
        [[self class] setEnabled:YES];
    }
    return self;
}

- (void)dealloc
{
    [[self class] setEnabled:NO];
    self.requestHandlers = nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public class methods

+(id)stubRequestsPassingTest:(OHHTTPStubsTestBlock)testBlock
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

+(id)addRequestHandler:(OHHTTPStubsRequestHandler)handler DEPRECATED_ATTRIBUTE
{
    return [self.sharedInstance addRequestHandler:handler];
}
+(BOOL)removeRequestHandler:(id)handler
{
    return [self.sharedInstance removeRequestHandler:handler];
}
+(void)removeLastRequestHandler
{
    [self.sharedInstance removeLastRequestHandler];
}
+(void)removeAllRequestHandlers
{
    [self.sharedInstance removeAllRequestHandlers];
}

+(void)setEnabled:(BOOL)enabled
{
    static BOOL currentEnabledState = NO;
    if (enabled && !currentEnabledState)
    {
        [NSURLProtocol registerClass:[OHHTTPStubsProtocol class]];
    }
    else if (!enabled && currentEnabledState)
    {
        // Force instanciate sharedInstance to avoid it being created later and this turning setEnabled to YES again
        (void)[self sharedInstance]; // This way if we call [setEnabled:NO] before any call to sharedInstance it will be kept disabled
        [NSURLProtocol unregisterClass:[OHHTTPStubsProtocol class]];
    }
    currentEnabledState = enabled;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public instance methods

-(id)addRequestHandler:(OHHTTPStubsRequestHandler)handler
{
    OHHTTPStubsRequestHandler handlerCopy = [handler copy];
    @synchronized(_requestHandlers)
    {
        [_requestHandlers addObject:handlerCopy];
    }
    return handlerCopy;
}

-(BOOL)removeRequestHandler:(id)handler
{
    BOOL handlerFound = [self.requestHandlers containsObject:handler];
    @synchronized(_requestHandlers)
    {
        [_requestHandlers removeObject:handler];
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
        for(OHHTTPStubsRequestHandler handler in [_requestHandlers reverseObjectEnumerator])
        {
            response = handler(request, onlyCheck);
            if (response) break;
        }
    }
    return response;
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
    return ([[OHHTTPStubs sharedInstance] responseForRequest:request onlyCheck:YES] != nil);
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
    NSURLRequest* request = [self request];
	id<NSURLProtocolClient> client = [self client];
    
    OHHTTPStubsResponse* responseStub = [[OHHTTPStubs sharedInstance] responseForRequest:request onlyCheck:NO];
    
    if (responseStub.error == nil)
    {
        // Send the fake data
        
        NSTimeInterval canonicalResponseTime = responseStub.responseTime;
        if (canonicalResponseTime<0)
        {
            // Interpret it as a bandwidth in KB/s ( -2 => 2KB/s )
            double bandwidth = -canonicalResponseTime * 1000.0; // in bytes per second
            canonicalResponseTime = responseStub.responseData.length / bandwidth;
        }
        NSTimeInterval requestTime = canonicalResponseTime * 0.1;
        NSTimeInterval responseTime = canonicalResponseTime - requestTime;
        
        NSHTTPURLResponse* urlResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                     statusCode:responseStub.statusCode
                                                                    HTTPVersion:@"HTTP/1.1"
                                                                   headerFields:responseStub.httpHeaders];
        
        // Cookies handling
        if (request.HTTPShouldHandleCookies)
        {
            NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:responseStub.httpHeaders forURL:request.URL];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:request.URL mainDocumentURL:request.mainDocumentURL];
        }
        
        
        NSString* redirectLocation = [responseStub.httpHeaders objectForKey:@"Location"];
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
            execute_after(responseTime, ^{
                if (!self.stopped)
                {
                    [client URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:urlResponse];
                }
            });
        }
        else
        {
            execute_after(requestTime,^{
                if (!self.stopped)
                {
                    [client URLProtocol:self didReceiveResponse:urlResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                    
                    execute_after(responseTime,^{
                        if (!self.stopped)
                        {
                            [client URLProtocol:self didLoadData:responseStub.responseData];
                            [client URLProtocolDidFinishLoading:self];
                        }
                    });
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

/////////////////////////////////////////////
// Delayed execution utility methods
/////////////////////////////////////////////

void execute_after(NSTimeInterval delayInSeconds, dispatch_block_t block)
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

@end
