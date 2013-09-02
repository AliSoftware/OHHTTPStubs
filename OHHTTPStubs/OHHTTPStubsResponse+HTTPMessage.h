//
//  OHHTTPStubsResponse+HTTPMessage.h
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 01/09/13.
//  Copyright (c) 2013 AliSoftware. All rights reserved.
//

#import "OHHTTPStubsResponse.h"

@interface OHHTTPStubsResponse (HTTPMessage)

/*! @name Building a response from HTTP Message data */

// TODO: Try to implement it using NSInputStream

/*! Builds a response given a message data as returned by `curl -is [url]`, that is containing both the headers and the body.
 This method will split the headers and the body and build a OHHTTPStubsReponse accordingly
 @param responseData The NSData containing the whole HTTP response, including the headers and the body
 @param requestTime The time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime If positive, the amount of time used to send the entire response.
 If negative, the rate in KB/s at which to send the response data.
 Useful to simulate slow networks for example.
 @return An OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
+(instancetype)responseWithHTTPMessageData:(NSData*)responseData
                               requestTime:(NSTimeInterval)requestTime
                              responseTime:(NSTimeInterval)responseTime;

/*! Builds a response given the name of a "*.response" file containing both the headers and the body.
 The response file is expected to be in the specified bundle (or the application bundle if nil).
 This method will split the headers and the body and build a OHHTTPStubsReponse accordingly
 @param responseName The name of the "*.response" file (without extension) containing the whole HTTP response (including the headers and the body)
 @param bundleOrNil The bundle in which the "*.response" file is located. If `nil`, the `[NSBundle bundleForClass:self.class]` will be used.
 @param requestTime The time to wait before the response begins to send. This value must be greater than or equal to zero.
 @param responseTime If positive, the amount of time used to send the entire response.
 If negative, the rate in KB/s at which to send the response data.
 Useful to simulate slow networks for example.
 @return An OHHTTPStubsResponse describing the corresponding response to return by the stub
 */
+(instancetype)responseNamed:(NSString*)responseName
                    inBundle:(NSBundle*)bundleOrNil
                 requestTime:(NSTimeInterval)requestTime
                responseTime:(NSTimeInterval)responseTime;








////////////////////////////////////////////////////////////////////////////////
#pragma mark - Deprecated Constructors (will be removed in 3.0)
/*! @name Deprecated initializers */

/*! Deprecated.
 
 For an exact equivalent of the behavior of this method, use this instead:
 
 [OHHTTPStubsResponse responseWithHTTPMessageData:responseData requestTime:responseTime*0.1 responseTime:responseTime*0.9]
 */
+(instancetype)responseWithHTTPMessageData:(NSData*)responseData
                              responseTime:(NSTimeInterval)responseTime
__attribute__((deprecated("Use responseWithHTTPMessageData:requestTime:responseTime: instead")));

/*! Deprecated.
 
 For an exact equivalent of the behavior of this method, use this instead:
 
 [OHHTTPStubsReponse responseNamed:responseName inBundle:bundle requestTime:responseTime*0.1 responseTime:responseTime*0.9]
 */
+(instancetype)responseNamed:(NSString*)responseName
                  fromBundle:(NSBundle*)bundle
                responseTime:(NSTimeInterval)responseTime
__attribute__((deprecated("Use responseNamed:inBundle:requestTime:responseTime: instead")));


@end
