//
//  OHHTTPStubsResponse+JSON.h
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 01/09/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import "OHHTTPStubsResponse.h"

@interface OHHTTPStubsResponse (JSON)

/*! Builds a response given a JSON object for the response body, status code, and headers.
 @param jsonObject Object representing the response body.
                   Typically a `NSDictionary`; may be any object accepted by `+[NSJSONSerialization dataWithJSONObject:options:error:]`
 @param statusCode The HTTP Status Code to use in the response
 @param httpHeaders The HTTP Headers to return in the response
                    If a "Content-Type" header is not included, "Content-Type: application/json" will be added.
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 
 @note This method typically calls responseWithData:statusCode:headers: passing the serialized JSON object as the data parameter and adding the Content-Type header if necessary.
 */
+ (instancetype)responseWithJSONObject:(id)jsonObject
                            statusCode:(int)statusCode
                               headers:(NSDictionary *)httpHeaders;

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Deprecated Constructors (will be removed in 3.0)
/*! @name Deprecated initializers */

@interface OHHTTPStubsResponse (Deprecated_JSON)

/*! @warning This method is deprecated
 
 For an equivalent of the behavior of this method, use this instead:
 <pre>
 `[[OHHTTPStubsResponse responseWithJSONObject:jsonObject statusCode:statusCode headers:httpHeaders]
  requestTime:responseTime*0.1 responseTime:responseTime*0.9]`
 </pre>
 
 @param jsonObject object representing the response body.
            Typically a `NSDictionary`; may be any object accepted by `+[NSJSONSerialization dataWithJSONObject:options:error:]`
 @param statusCode the HTTP statuc doe to use in the response
 @param responseTime the time to wait before the response is sent
 @param httpHeaders The HTTP headers to return in the response.
            If a Content-Type header is not included, "Content-Type: application/json" will be added.

 @return an `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
+ (instancetype)responseWithJSONObject:(id)jsonObject
                            statusCode:(int)statusCode
                          responseTime:(NSTimeInterval)responseTime
                               headers:(NSDictionary*)httpHeaders
__attribute__((deprecated("Use responseWithJSONObject:statusCode:headers: and requestTime:responseTime: instead")));

@end
