//
//  OHHTTPStubsProtocol.h
//  OHHTTPStubs
//
//  Created by Nickolas Pohilets on 29.04.17.
//  Copyright © 2017 AliSoftware. All rights reserved.
//

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
