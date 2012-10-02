OHHTTPStubs
===========

A class to stub network requests easily: test your apps with fake network data (stubbed from file) and custom response time

* [Basic Usage](#basic-usage)
* [The OHHTTPStubsResponse object](#the-ohhttpstubsresponse-object)
* [Advanced Usage](#advanced-usage)
 * [Return a response depending on the request](#return-a-response-depending-on-the-request)
 * [Using download speed instead of responseTime](#using-download-speed-instead-of-responsetime)
 * [Return quickly when `onlyCheck=YES`](#return-quickly-when-onlycheckyes)
 * [Stack multiple requestHandlers](#stack-multiple-requesthandlers)
* [Complete Example](#complete-example)
* [Change Log](#change-log)
* [ARC Support](#arc-support)
* [License and Credits](#license-and-credits)

----

## Basic Usage

This is aimed to be very simple to use. It uses block to intercept outgoing requests and allow you to
return data from a file instead.

This is the most simple way to use it:

    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
     {
       return [OHHTTPStubsResponse responseWithFile:@"response.json" contentType:@"text/json" responseTime:2.0];
     }];

This will return the `NSData` corresponding to the content of the "`response.json`" file (that must be in your bundle)
with a "`Content-Type`" header of "`text/json`" in the HTTP response, after 2 seconds.

## The OHHTTPStubsResponse object

Each time a network request is done by your application
 (whatever the framework used, `NSURLConnection`, [AFNetworking](https://github.com/AFNetworking/AFNetworking/), or anything else)
this requestHandler block will be called, allowing you to return an `OHHTTPStubsResponse` object
describing the response to return. If you return a non-nil `OHHTTPStubsResponse`, it will automatically
build a NSURLResponse and behave exactly like if you received the response from the network.
_If your return `nil`, the normal request will be sent._

The `OHHTTPStubsResponse` class exposes multiple initializers:

##### The designed intializer
    +(id)responseWithData:(NSData*)data
               statusCode:(int)statusCode
             responseTime:(NSTimeInterval)responseTime
                  headers:(NSDictionary*)httpHeaders;

##### Commodity initializer to load data from a file in your bundle
    +(id)responseWithFile:(NSString*)fileName
               statusCode:(int)statusCode
             responseTime:(NSTimeInterval)responseTime
                  headers:(NSDictionary*)httpHeaders;

##### Useful short-form initializer to load data from a file in your bundle, using the specified "Content-Type" header
    +(id)responseWithFile:(NSString*)fileName
              contentType:(NSString*)contentType
             responseTime:(NSTimeInterval)responseTime;
             
##### To respond with an error instead of a success
    +(id)responseWithError:(NSError*)error;
_(e.g. you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:nil]`)_


## Advanced Usage

### Return a response depending on the request

Of course, and that's the main reason this is implemented with blocks,
you can do whatever you need in the block implementation. This includes
checking the request URL to see if you want to return a stub or not,
and pick the right file according to the requested URL.

Example:

    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
     {
       if ([request.URL.absoluteString hasPrefix:@".json"]) {
         NSString* basename = [request.URL.absoluteString lastPathComponent]
         return [OHHTTPStubsResponse responseWithFile:basename contentType:@"text/json" responseTime:2.0];
       } else {
         return nil; // Don't stub
       }
     }];


### Using download speed instead of responseTime

When building the `OHHTTPStubsResponse` object, you can specify a response time (in seconds) so
that the sending of the fake response will be postponed (using GCD's `dispatch_after function`).
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

### Return quickly when `onlyCheck=YES`

If the `onlyCheck` parameter of the requestHandler block is `YES`, then it means that the handler is called
   only to check if you will be able to return a stubbed response or if it has to do the standard request.
In this scenario, the response will not actually be used but will only be compared to `nil` to check if it has to be stubbed later.
   _The handler will be called later again (with `onlyCheck=NO`) to fetch the actual OHHTTPStubsResponse object._
   
So in such cases (`onlyCheck==YES`), you can simply return `nil` if you don't want to provide a stubbed response,
   and **_any_ non-nil value** to indicate that you will provide a stubbed response later.

This may be useful if you intend to do some no-so-fast work to build your real `OHHTTPStubsResponse`
  (like reading some large file for example): in that case you can quickly return a dummy value when `onlyCheck==YES`
  without the burden of building the actual `OHHTTPStubsResponse` object.
You will obviously return the real `OHHTTPStubsResponse` in the later call when `onlyCheck==NO`.

There is a macro `OHHTTPStubsResponseUseStub` provided in the header that you can use as a dummy return value
  for that purpose _(it actually evaluates to `(OHHTTPStubsReponse*)1`)_


### Stack multiple requestHandlers

You can call `+addRequestHandler:` multiple times.
It will just add the response handlers in an internal list of handler.

When a network request is performed by the system, the response handlers are called in the reverse
  order that they have been added, the last added handler having priority over the first added ones.
  The first non-nil OHHTTPStubsResponse returned is used to reply to the request.

_This may be useful to install different stubs in different classes (say different UIViewControllers) and various places in your application._

You can remove the latest added handler with the `removeLastRequestHandler` method.

You can also remove any given handler with the `removeRequestHandler:` method. This method takes as a parameter the object returned by `addRequestHandler:`. _Note that this returned object is already retained by OHHTTPStubs, so you may keep it in a `__weak` variable._

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
     
     ...
     
    // Then this call (sending a request using the AFNetworking framework) will actually
    // receive a fake response issued from the file "file1.json"
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.example.com/file1"]];
    AFJSONRequestOperation* req =
    [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
     {
        ...
     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
     {
        ...
     }];
    [req start];



## Change Log

The changelog is available [here in the dedicated wiki page](https://github.com/AliSoftware/OHHTTPStubs/wiki/ChangeLog).

## ARC Support

This classes now support both ARC and non-ARC projects :)

## License and Credits

This project is brought to you by Olivier Halligon and is under MIT License

It has been inspired by [this article from InfiniteLoop.dk](http://www.infinite-loop.dk/blog/2011/09/using-nsurlprotocol-for-injecting-test-data/)
_(See also his [GitHub repository](https://github.com/InfiniteLoopDK/ILTesting))_

