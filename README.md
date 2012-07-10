OHHTTPStubs
===========

A class to stub network requests easily: test your apps with fake network data (stubbed from file) and custom response time
Original idea: https://github.com/InfiniteLoopDK/ILTesting

## Basic Usage

This is aimed to be very simple to use. It uses block to intercept outgoing requests and allow you to
return data from a file instead.

This is the most simple way to use it:

    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
     {
         return [OHHTTPStubsResponse responseWithFile:@"response.json" contentType:@"text/json" responseTime:0.0];
     }];

This will return the NSData corresponding to the content of the "response.json" file (that must be in your bundle)
with a "Content-Type" header of "text/json" in the HTTP response, after 2 seconds

### The OHHTTPStubsResponse object

Each time a network request is done by your application
 (whatever the framework used, NSURLConnection, AFNetworking, or whatever)
this requestHandler will be called, allowing you to return an `OHHTTPStubsResponse` object
describing the response to return. If you return a non-nil `OHHTTPStubsResponse`, it will automatically
build a NSURLResponse and behave exactly like if you received the response from the network.

The `OHHTTPStubsResponse` class exposes multiple initializers:
* `+(id)responseWithData:(NSData*)data statusCode:(int)statusCode responseTime:(NSTimeInterval)responseTime headers:(NSDictionary*)httpHeaders;` which is the most complete (designed intializer)
* `+(id)responseWithFile:(NSString*)fileName statusCode:(int)statusCode responseTime:(NSTimeInterval)responseTime headers:(NSDictionary*)httpHeaders;` which is a commodity initializer to load data from a file in your bundle
* `+(id)responseWithFile:(NSString*)fileName contentType:(NSString*)contentType responseTime:(NSTimeInterval)responseTime;` which is probably the most useful short-form to load data from a file in your bundle, using the specified "Content-Type" header
* `+(id)responseWithError:(NSError*)error;` to respond with an error instead of a success (e.g. `[NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:nil]`)


## Advanced Usage

### Return quickly when onlyCheck=YES

If the `onlyCheck` parameter is `YES, then it means that the handler is called only to check if
   you will be able to return a stubbed response or if it has to do the standard request.
   In this scenario, the response will not actually be used but will only be compared to nil.
   The handler will be called later again (with `onlyCheck=NO`) to fetch the actual OHHTTPStubsResponse object.
   
So in such cases (`onlyCheck=YES`), you can simply return nil if you don't want to provide a stubbed response,
   and _any_ non-nil value to indicate that you will provide a stubbed response later.
There is a macro for that purpose, called `OHHTTPStubsResponseUseStub` to allow you to return
   quickly in such cases without the burden of building an actual OHHTTPStubsResponse object.

### Return a response depending on the request

Of course, and that's the main reason this is implemented with blocks,
you can do whatever you need in the block implementation. This includes
checking the request URL to see if you want to return a stub or not,
and pick the right file according to the requested URL.

### Using download speed instead of responseTime

When building the `OHHTTPStubsResponse` object, you can specify a response time (in seconds) so
that the sending of the fake response will be postponed (using GCD's dispatch_after function).
This allows you to simulate a slow network for example.

If you specify a negative value for the responseTime parameter, instead of being interpreted as
a time in seconds, it will be interpreted as a download speed in KBytes/s.
In that case, the response time will be computed using the size of the response's data to simulate
the indicated download speed.

The `OHHTTPStubsResponse` header defines some constants for standard download speeds:
* `OHHTTPStubsDownloadSpeedGPRS`   :    56 kbps (7 KB/s)
* `OHHTTPStubsDownloadSpeedEDGE`   :   128 kbps (16 KB/s)
* `OHHTTPStubsDownloadSpeed3G`     :  3200 kbps (400 KB/s)
* `OHHTTPStubsDownloadSpeed3GPlus` :  7200 kbps (900 KB/s)
* `OHHTTPStubsDownloadSpeedWifi`   : 12000 kbps (1500 KB/s)

## Complete example

    NSArray* stubs = [NSArray arrayWithObjects:@"file1", @"file2", nil];
                           
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
     {
         NSString* basename = [request.URL.absoluteString lastPathComponent];
         if (onlyCheck) {
         	return ([stubs containsObject:basename] ? OHHTTPStubsResponseUseStub : nil);
		 }
         
         NSString* file = [basename stringByAppendingPathExtension:@"json"];
         return [OHHTTPStubsResponse responseWithFile:file contentType:@"text/json"
                                         responseTime:OHHTTPStubsDownloadSpeedEDGE];
     }];


## ARC Support

This classes are not using ARC.

If you want to use it in an ARC-enabled project, you must add the "-fobjc-arc" compiler flag
to OHHTTPStubs.m and OHHTTPStubsResponse.m in Target Settings > Build Phases > Compile Sources.


## Credits

This project is brought to you by Olivier Halligon.

It has been inspired by [this article from InfiniteLoop.dk](http://www.infinite-loop.dk/blog/2011/09/using-nsurlprotocol-for-injecting-test-data/)
