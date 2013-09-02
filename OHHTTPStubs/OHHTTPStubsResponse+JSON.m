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
