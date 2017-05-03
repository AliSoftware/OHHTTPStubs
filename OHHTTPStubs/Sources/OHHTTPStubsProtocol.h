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

#import <Foundation/Foundation.h>
#import "OHHTTPStubsDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OHHTTPStubsManager <NSObject>

- (OHHTTPStubsDescriptor* _Nullable)firstStubPassingTestForRequest:(NSURLRequest*)request;

@property(atomic, readonly, copy, nullable) void (^onStubActivationBlock)(NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse*);
@property(atomic, readonly, copy, nullable) void (^onStubRedirectBlock)(NSURLRequest*, NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse*);
@property(atomic, readonly, copy, nullable) void (^afterStubFinishBlock)(NSURLRequest*, id<OHHTTPStubsDescriptor>, OHHTTPStubsResponse* _Nullable, NSError*);

@end

/// Proxy for the class object of the OHHTTPStubsProtocol that injects OHHTTPStubsManager into created instance of OHHTTPStubsProtocol
@interface OHHTTPStubsProtocolClassProxy : NSProxy

- (instancetype)initWithManager:(id<OHHTTPStubsManager>)manager;

@end

/// Proxy for the instance of OHHTTPStubsProtocol that was allocated, but not yet initialized.
@interface OHHTTPStubsProtocolInstanceProxy : NSProxy

- (instancetype)initWithManager:(id<OHHTTPStubsManager>)manager;

@property(atomic, weak, readonly) id<OHHTTPStubsManager> manager;

@end

@interface OHHTTPStubsProtocol : NSURLProtocol

- (id)initWithManager:(id<OHHTTPStubsManager>)manager
              request:(NSURLRequest *)request
       cachedResponse:(NSCachedURLResponse *)response
               client:(id<NSURLProtocolClient>)client;

@end

NS_ASSUME_NONNULL_END
