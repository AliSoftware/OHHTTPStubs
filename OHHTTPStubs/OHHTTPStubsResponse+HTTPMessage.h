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
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
+(instancetype)responseWithHTTPMessageData:(NSData*)responseData;

/*! Builds a response given the name of a `"*.response"` file containing both the headers and the body.
 The response file is expected to be in the specified bundle (or the application bundle if nil).
 This method will split the headers and the body and build a OHHTTPStubsReponse accordingly
 @param responseName The name of the `"*.response"` file (without extension) containing the whole HTTP response (including the headers and the body)
 @param bundleOrNil The bundle in which the `"*.response"` file is located. If `nil`, the `[NSBundle bundleForClass:self.class]` will be used.
 @return An `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
+(instancetype)responseNamed:(NSString*)responseName
                    inBundle:(NSBundle*)bundleOrNil;


@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Deprecated Constructors (will be removed in 3.0)
/*! @name Deprecated initializers */

@interface OHHTTPStubsResponse (Deprecated_HTTPMessage)

/*! @warning This method is deprecated
 
 For an equivalent of the behavior of this method, use this instead:
 <pre>
 `[[OHHTTPStubsResponse responseWithHTTPMessageData:responseData]
   requestTime:responseTime*0.1 responseTime:responseTime*0.9]`
 </pre>
 
 @param responseData the NSData containing the whole HTTP response, including the headers and the body
 @param responseTime the time to wait before the response is sent (to simulate slow networks for example)
 @return an `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
+(instancetype)responseWithHTTPMessageData:(NSData*)responseData
                              responseTime:(NSTimeInterval)responseTime
__attribute__((deprecated("Use responseWithHTTPMessageData: and requestTime:responseTime: instead")));

/*! @warning This method is deprecated
 
 For an equivalent of the behavior of this method, use this instead:
 <pre>
 `[[OHHTTPStubsReponse responseNamed:responseName inBundle:bundle]
   requestTime:responseTime*0.1 responseTime:responseTime*0.9]`
 </pre>
 
 @param responseName the name of the `"*.response"` file (without extension) containing the whole HTTP response (including the headers and the body)
 @param bundle the bundle in which the `"*.response"` file is located. If `nil`, the `[NSBundle bundleForClass:self.class]` will be used.
 @param responseTime the time to wait before the response is sent (to simulate slow networks for example)
 @return an `OHHTTPStubsResponse` describing the corresponding response to return by the stub
 */
+(instancetype)responseNamed:(NSString*)responseName
                  fromBundle:(NSBundle*)bundle
                responseTime:(NSTimeInterval)responseTime
__attribute__((deprecated("Use responseNamed:inBundle: and requestTime:responseTime: instead")));


@end
