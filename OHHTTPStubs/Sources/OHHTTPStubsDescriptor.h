//
//  OHHTTPStubsDescriptor.h
//  OHHTTPStubs
//
//  Created by Nickolas Pohilets on 29.04.17.
//  Copyright © 2017 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OHHTTPStubsTypes.h"

@interface OHHTTPStubsDescriptor : NSObject <OHHTTPStubsDescriptor>

+ (instancetype)stubDescriptorWithTestBlock:(OHHTTPStubsTestBlock)testBlock
                              responseBlock:(OHHTTPStubsResponseBlock)responseBlock;

@property(atomic, copy) OHHTTPStubsTestBlock testBlock;
@property(atomic, copy) OHHTTPStubsResponseBlock responseBlock;

@end
