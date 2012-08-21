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

#import "OHHTTPStubs.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Types

@interface OHHTTPStubsProtocol : NSURLProtocol @end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Interface

@interface OHHTTPStubs()
@property(nonatomic, retain) NSMutableArray* requestHandlers;
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Implementation

@implementation OHHTTPStubs
@synthesize requestHandlers = _requestHandlers;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton methods

+ (OHHTTPStubs*)sharedInstance
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
        self.requestHandlers = [NSMutableArray array];
        [[self class] setEnabled:YES];
    }
    return self;
}

- (void)dealloc
{
    [[self class] setEnabled:NO];
    self.requestHandlers = nil;
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public class methods

// Commodity methods
+(id)addRequestHandler:(OHHTTPStubsRequestHandler)handler
{
    return [[self sharedInstance] addRequestHandler:handler];
}
+(BOOL)removeRequestHandler:(id)handler
{
    return [[self sharedInstance] removeRequestHandler:handler];
}
+(void)removeLastRequestHandler
{
    [[self sharedInstance] removeLastRequestHandler];
}
+(void)removeAllRequestHandlers
{
    [[self sharedInstance] removeAllRequestHandlers];
}

+(void)setEnabled:(BOOL)enabled
{
    if (enabled)
    {
        [NSURLProtocol registerClass:[OHHTTPStubsProtocol class]];
    }
    else
    {
        [NSURLProtocol unregisterClass:[OHHTTPStubsProtocol class]];
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public instance methods

-(id)addRequestHandler:(OHHTTPStubsRequestHandler)handler
{
    OHHTTPStubsRequestHandler handlerCopy = [handler copy];
    [self.requestHandlers addObject:handlerCopy];
#if ! __has_feature(objc_arc)
    [handlerCopy autorelease];
#endif
    return handlerCopy;
}

-(BOOL)removeRequestHandler:(id)handler
{
    BOOL handlerFound = [self.requestHandlers containsObject:handler];
    [self.requestHandlers removeObject:handler];
    return handlerFound;
}
-(void)removeLastRequestHandler
{
    [self.requestHandlers removeLastObject];
}

-(void)removeAllRequestHandlers
{
    [self.requestHandlers removeAllObjects];
}

@end











////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Protocol Class

// Undocumented initializer obtained by class-dump
// Don't use this in production code destined for the App Store
@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL
       statusCode:(NSInteger)statusCode
     headerFields:(NSDictionary*)headerFields
      requestTime:(double)requestTime;
@end

@implementation OHHTTPStubsProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSArray* requestHandlers = [OHHTTPStubs sharedInstance].requestHandlers;
    id response = nil;
    for(OHHTTPStubsRequestHandler handler in [requestHandlers reverseObjectEnumerator])
    {
        response = handler(request, YES);
        if (response) break;
    }
    return (response != nil);
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
    
    OHHTTPStubsResponse* responseStub = nil;
    NSArray* requestHandlers = [OHHTTPStubs sharedInstance].requestHandlers;
    for(OHHTTPStubsRequestHandler handler in [requestHandlers reverseObjectEnumerator])
    {
        responseStub = handler(request, NO);
        if (responseStub) break;
    }
    
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
        
        NSHTTPURLResponse* urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                                     statusCode:responseStub.statusCode
                                                                   headerFields:responseStub.httpHeaders
                                                                    requestTime:requestTime];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, requestTime*NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            //NSLog(@"[OHHTTPStubs] Stub Response for %@ received", [request URL]);
            [client URLProtocol:self didReceiveResponse:urlResponse
             cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, responseTime*NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                //NSLog(@"[OHHTTPStubs] Stub Data for %@ received", [request URL]);
                [client URLProtocol:self didLoadData:responseStub.responseData];
                [client URLProtocolDidFinishLoading:self];
            });
        });
#if ! __has_feature(objc_arc)
        [urlResponse autorelease];
#endif
    } else {
        // Send the canned error
        [client URLProtocol:self didFailWithError:responseStub.error];
    }
}

- (void)stopLoading
{
}

@end