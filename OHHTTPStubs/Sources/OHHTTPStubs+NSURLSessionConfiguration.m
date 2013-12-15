//
//  NSURLSessionConfiguration+OHHTTPStubs.m
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 06/10/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

#if defined(__IPHONE_7_0) || defined(__MAC_10_9)

#import <objc/runtime.h>
#import "OHHTTPStubs.h"


//////////////////////////////////////////////////////////////////////////////////////////////////

/*! This helper is used to swizzle NSURLSessionConfiguration constructor methods
    defaultSessionConfiguration and ephemeralSessionConfiguration to insert the private
    OHHTTPStubsProtocol into their protocolClasses array so that OHHTTPStubs is automagically
    supported when you create a new NSURLSession based on one of there configurations.
 */

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;
static SessionConfigConstructor orig_ephemeralSessionConfiguration;

static SessionConfigConstructor OHHTTPStubsSwizzle(SEL selector, SessionConfigConstructor newImpl)
{
    Class cls = NSURLSessionConfiguration.class;
    Class metaClass = object_getClass(cls);
    
    Method origMethod = class_getClassMethod(cls, selector);
    SessionConfigConstructor origImpl = (SessionConfigConstructor)method_getImplementation(origMethod);
    if (!class_addMethod(metaClass, selector, (IMP)newImpl, method_getTypeEncoding(origMethod)))
    {
        method_setImplementation(origMethod, (IMP)newImpl);
    }
    return origImpl;
}

static void OHHTTPStubsAddProtocolClassToNSURLSessionConfiguration(NSURLSessionConfiguration* config)
{
    NSMutableArray* protocolClasses = [NSMutableArray arrayWithArray:config.protocolClasses];
    // objc_getClass loads the class in the ObjC Runtime if not loaded at that time, so it's secure.
    Class protocolClass = objc_getClass("OHHTTPStubsProtocol");
    if (![protocolClasses containsObject:protocolClass])
        [protocolClasses addObject:protocolClass];
    config.protocolClasses = protocolClasses;
}

static NSURLSessionConfiguration* OHHTTPStubs_defaultSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_defaultSessionConfiguration(self,_cmd); // call original method
    OHHTTPStubsAddProtocolClassToNSURLSessionConfiguration(config);
    return config;
}

static NSURLSessionConfiguration* OHHTTPStubs_ephemeralSessionConfiguration(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_ephemeralSessionConfiguration(self,_cmd); // call original method
    OHHTTPStubsAddProtocolClassToNSURLSessionConfiguration(config);
    return config;
}

void _OHHTTPStubs_InstallNSURLSessionConfigurationMagicSupport()
{
    orig_defaultSessionConfiguration = OHHTTPStubsSwizzle(@selector(defaultSessionConfiguration),
                                                          OHHTTPStubs_defaultSessionConfiguration);
    orig_ephemeralSessionConfiguration = OHHTTPStubsSwizzle(@selector(ephemeralSessionConfiguration),
                                                            OHHTTPStubs_ephemeralSessionConfiguration);
}

#else
void _OHHTTPStubs_InstallNSURLSessionConfigurationMagicSupport()
{
    /* NO-OP for Xcode4 and pre-iOS7/pre-OSX9 SDKs that does not support NSURLSessionConfiguration */
}
#endif
