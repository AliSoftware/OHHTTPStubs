//
//  OHHTTPStubsResponse+JSON.m
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 01/09/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import "OHHTTPStubsResponse+JSON.h"

@implementation OHHTTPStubsResponse (JSON)

/*! @name Building a response from JSON objects */

+ (instancetype)responseWithJSONObject:(id)jsonObject
                            statusCode:(int)statusCode
                               headers:(NSDictionary *)httpHeaders
{
    if (!httpHeaders[@"Content-Type"])
    {
        NSMutableDictionary *mutableHeaders = [httpHeaders mutableCopy];
        mutableHeaders[@"Content-Type"] = @"application/json";
        httpHeaders = mutableHeaders;
    }
    
    return [self responseWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil]
                       statusCode:statusCode
                          headers:httpHeaders
            ];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Deprecated Constructors

@implementation OHHTTPStubsResponse (Deprecated_JSON)

+ (instancetype)responseWithJSONObject:(id)jsonObject
                            statusCode:(int)statusCode
                          responseTime:(NSTimeInterval)responseTime
                               headers:(NSDictionary*)httpHeaders
{
    return [[self responseWithJSONObject:jsonObject statusCode:statusCode headers:httpHeaders]
            requestTime:(responseTime<0)?0:responseTime*0.1
            responseTime:(responseTime<0)?responseTime:responseTime*0.9];
}

@end
