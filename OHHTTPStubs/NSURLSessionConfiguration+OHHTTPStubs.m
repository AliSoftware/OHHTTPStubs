//
//  NSURLSessionConfiguration+OHHTTPStubs.m
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 06/10/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

#if 1
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000)

#import <objc/runtime.h>
#import "OHHTTPStubs.h"

@interface NSURLSessionConfiguration (OHHTTPStubs) @end

//////////////////////////////////////////////////////////////////////////////////////////////////

/*! This category automatically swizzle the defaultSessionConfiguration & ephemeralSessionConfiguration
    to add the private OHHTTPStubsProtocol to the list of supported protocols by default
 
 @note Custom NSURLProtocol subclasses are not available in background sessions.
       This is why the swizzling is not done on the `backgroundSessionConfiguration` constructor.
*/
@implementation NSURLSessionConfiguration (OHHTTPStubs)

typedef NSURLSessionConfiguration*(*SessionConfigConstructor)(id,SEL);
static SessionConfigConstructor orig_defaultSessionConfiguration;
static SessionConfigConstructor orig_ephemeralSessionConfiguration;

static SessionConfigConstructor OHHTTPStubsSwizzle(Class cls, SEL selector, SessionConfigConstructor newImpl)
{
    Class metaClass = object_getClass(cls);
    
    Method origMethod = class_getClassMethod(cls, selector);
    SessionConfigConstructor origImpl = (SessionConfigConstructor)method_getImplementation(origMethod);
    if (!class_addMethod(metaClass, selector, (IMP)newImpl, method_getTypeEncoding(origMethod)))
    {
        method_setImplementation(origMethod, (IMP)newImpl);
    }
    return origImpl;
}

static void OHTTPStubsAddProtocolClassToConfig(NSURLSessionConfiguration* config)
{
    NSMutableArray* protocolClasses = [NSMutableArray arrayWithArray:config.protocolClasses];
    // objc_getClass loads the class in the ObjC Runtime if not loaded at that time, so it's secure.
    Class protocolClass = objc_getClass("OHHTTPStubsProtocol");
    [protocolClasses addObject:protocolClass];
    config.protocolClasses = protocolClasses;
}

static NSURLSessionConfiguration* defaultSessionConfigurationWithOHHTTPStubs(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_defaultSessionConfiguration(self,_cmd); // call original method
    OHTTPStubsAddProtocolClassToConfig(config);
    return config;
}

static NSURLSessionConfiguration* ephemeralSessionConfigurationWithOHHTTPStubs(id self, SEL _cmd)
{
    NSURLSessionConfiguration* config = orig_ephemeralSessionConfiguration(self,_cmd); // call original method
    OHTTPStubsAddProtocolClassToConfig(config);
    return config;
}

+ (void)load
{
    orig_defaultSessionConfiguration = OHHTTPStubsSwizzle(self,
                                                          @selector(defaultSessionConfiguration),
                                                          defaultSessionConfigurationWithOHHTTPStubs);
    orig_ephemeralSessionConfiguration = OHHTTPStubsSwizzle(self,
                                                            @selector(ephemeralSessionConfiguration),
                                                            ephemeralSessionConfigurationWithOHHTTPStubs);
}


@end

#endif
#endif
