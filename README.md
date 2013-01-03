OHHTTPStubs
===========

A class to stub network requests easily: test your apps with fake network data (stubbed from file) and custom response time

* [Basic Usage](#basic-usage)
* [The `OHHTTPStubsResponse` object](#the-ohhttpstubsresponse-object)
* [Advanced Usage](#advanced-usage)
 * [Return a response depending on the request](#return-a-response-depending-on-the-request)
 * [Using download speed instead of responseTime](#using-download-speed-instead-of-responsetime)
 * [Return quickly when `onlyCheck=YES`](#return-quickly-when-onlycheckyes)
 * [Stack multiple requestHandlers](#stack-multiple-requesthandlers)
* [Complete Examples](#complete-examples)
* [Installing in your projects](#installing-in-your-projects)
* [About OHHTTPStubs Unit Tests](#about-ohhttpstubs-unit-tests)
* [Change Log](#change-log)
* [License and Credits](#license-and-credits)

----

## Basic Usage

This is aimed to be very simple to use. It uses block to intercept outgoing requests and allow you to
return data from a file instead.

##### This is the most simple way to use it:

    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck) {
        return [OHHTTPStubsResponse responseWithFile:@"response.json" contentType:@"text/json" responseTime:2.0];
    }];
     
This will return the `NSData` corresponding to the content of the `"response.json"` file (that must be in your bundle)
with a `"Content-Type"` header of `"text/json"` in the HTTP response, after 2 seconds.

##### We can also conditionally stub only certain requests, like this:

    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        // Only stub requests to "*.json" files
        return [request.URL.absoluteString.lastPathComponent.pathExtension isEqualToString:@"json"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        // Stub it with our "response.json" stub file
        return [OHHTTPStubsResponse responseWithFile:@"response.json" contentType:@"text/json" responseTime:2.0];
    }];

##### Then each time a network request is done by your application

For every request sent, whatever the framework used (`NSURLConnection`,
[`AFNetworking`](https://github.com/AFNetworking/AFNetworking/), or anything else):

* If you used `shouldStubRequestsPassingTest:withStubResponse:`
  * The block passed as first argument will be called to check if we need to stub this request.
  * If this block returned YES, the block passed as second argument will be called to let you return an `OHHTTPStubsResponse` object, describing the fake response to return.
* If you used `addRequestHandler:`
  * If you return a non-nil `OHHTTPStubsResponse`, the request will be stubbed by returning the corresponding fake response.
  * If your return `nil`, the normal request will be sent (no stubbing).

_(See also "[Return quickly when `onlyCheck=YES`](#return-quickly-when-onlycheckyes)" below)_


## The `OHHTTPStubsResponse` object

The `OHHTTPStubsResponse` class, describing the fake response to return, exposes multiple initializers:

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

You can use either `addRequestHandler:` or `shouldStubRequestsPassingTest:withStubResponse:` to install a stubbed request.
[See below](#return-quickly-when-onlycheckyes).

Example:

    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse*(NSURLRequest *request, BOOL onlyCheck)
     {
       NSString* basename = request.URL.absoluteString.lastPathComponent;
       if ([basename.pathExtension isEqualToString:@"json"]) {
         return [OHHTTPStubsResponse responseWithFile:basename contentType:@"text/json" responseTime:2.0];
       } else {
         return nil; // Don't stub
       }
     }];


### Using download speed instead of responseTime

When building the `OHHTTPStubsResponse` object, you can specify a response time (in seconds) so
that the sending of the fake response will be postponed. This allows you to simulate a slow network for example.

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

When using `addRequestHandler:`, if the `onlyCheck` parameter of the requestHandler block is `YES`, then it means that the handler is called
   only to check if you will be able to return a stubbed response or if it has to do the standard request.
In this scenario, the response will not actually be used but will only be compared to `nil` to check if it has to be stubbed later.
   _The handler will be called later again (with `onlyCheck=NO`) to fetch the actual `OHHTTPStubsResponse` object._
   
So in such cases (`onlyCheck==YES`), you can simply return `nil` if you don't want to provide a stubbed response,
   and **_any_ non-nil value** to indicate that you will provide a stubbed response later.

This may be useful if you intend to do some not-so-fast work to build your real `OHHTTPStubsResponse`
  (like reading some large file for example): in that case you can quickly return a dummy value when `onlyCheck==YES`
  without the burden of building the actual `OHHTTPStubsResponse` object.
You will obviously return the real `OHHTTPStubsResponse` in the later call when `onlyCheck==NO`.

_There is a macro `OHHTTPStubsResponseUseStub` provided in the header that you can use as a dummy return value for that purpose._

---

To avoid forgetting about quickly return if the handler is called only for checking the availability of a stub, you may
prefer using the `shouldStubRequestsPassingTest:withStubResponse:` class method, which uses two distinct blocks: one to
only quickly check that the request should be stubbed, and the other to build and return the actual stubbed response.

Example:

    [OHHTTPStubs shouldStubRequestPassingTest:^BOOL(NSURLRequest *request) {
        NSString* basename = request.URL.absoluteString.lastPathComponent;
        return [basename.pathExtension isEqualToString:@"json"]; // only stub requests for "*.json" files
    } withStubResponse:^OHHTTPStubsResponse* (NSURLRequest* request))handler {
        // This block will only be called if the previous one has returned YES (so only for "*.json" files)
        NSString* basename = request.URL.absoluteString.lastPathComponent;
        return [OHHTTPStubsResponse responseWithFile:basename contentType:@"text/json" responseTime:2.0];
    }];

> Note: in practice, this method calls `addResponseHandler:`, and pass it a new block that:
> * calls the first block to check if we need to stub, and
> * directly return `OHHTTPStubsResponseUseStub` or `OHHTTPStubsResponseDontUseStub` if `onlyCheck=YES`
> * or call the second block to return the actual stub only if `onlyCheck=NO`.

_Note that even if you want to stub all your requests unconditionally, it is still better to
use `shouldStubRequestsPassingTest:withStubResponse:` with the first block always returning `YES`,
because it will prevent building the whole stubbed response multiple times (once or more when only checking,
and one final time when actually returning it)._


### Stack multiple requestHandlers

You can call `addRequestHandler:` or `shouldStubRequestsPassingTest:withStubResponse:` multiple times.
It will just add the response handlers in an internal list of handlers.

When a network request is performed by the system, the response handlers are called in the reverse
  order that they have been added, the last added handler having priority over the first added ones.
  The first handler that returns a stub (non-nil response for `addRequestHandler:`,
  or first block returning YES for `shouldStubRequestsPassingTest:withStubResponse:`) is then used to reply to the request.

_This may be useful to install different stubs in different classes (say different UIViewControllers)
and various places in your application, or to separate different stubs and stubbing conditions
(like some stubs for images and other stubs for JSON files) more easily.
See the `OHHTTPStubsDemo` project for a typical example._

You can remove the latest added handler with the `removeLastRequestHandler` method.

You can also remove any given handler with the `removeRequestHandler:` method.
This method takes as a parameter the object returned by `addRequestHandler:` or `shouldStubRequestsPassingTest:withStubResponse:`.
_Note that this returned object is already retained by `OHHTTPStubs` while the stub is installed,
so you may keep it in a `__weak` variable (no need to keep a `__strong` reference)._



## Complete examples

Here is another example code below that uses the various techniques explained above.
For a complete Xcode projet, see the `OHHTTPStubsDemo.xcworkspace` project in the repository.


    NSArray* stubs = [NSArray arrayWithObjects:@"file1", @"file2", nil];
                           
    [OHHTTPStubs shouldStubRequestPassingTest:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [stubs containsObject:request.URL.absoluteString.lastPathComponent];
    } withStubResponse:^OHHTTPStubsResponse* (NSURLRequest* request))handler {
        NSString* file = [request.URL.absoluteString.lastPathComponent
                          stringByAppendingPathExtension:@"json"];
        return [OHHTTPStubsResponse responseWithFile:file contentType:@"text/json"
                                         responseTime:OHHTTPStubsDownloadSpeedEDGE];
    }];
     
     ...
     
    // Then this call (sending a request using the AFNetworking framework) will actually
    // receive a fake response issued from the file "file1.json"
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.example.com/file1"]];
    [[AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
     {
        ...
     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
     {
        ...
     }] start];



## Installing in your projects

The `OHHTTPStubs` project is provided as a Xcode project that generates a static library, to easily integrate it with your project.

1. Add the `OHHTTPStubs.xcodeproj` project to your application workspace, next to your application project
2. Link `libOHHTTPStubs.a` with your application project:
  * Select your application project in the Project Navigator, then select your target in which you want to use `OHHTTPStubs`
     (for example **your Tests target** if you will only use `OHHTTPStubs` in your Unit Tests)
  * Go to the "Build Phase" tab and open the "Link Binary With Libraries" phase
  * Use the "+" button to add the `libOHHTTPStubs.a` library to the libraries linked with your project
3. When you need to use `OHHTTPStubs` classes, import the headers using square brackets: `#import <OHHTTPStubs/OHHTTPStubs.h>`

_Note: due to a bug in Xcode4, you will have to ensure that the `libOHHTTPStubs.a` file reference added in your project
has its path referenced as "Relative to Build Products" as it should.
If it is not the case, please read the [detailed instructions here](http://github.com/AliSoftware/OHHTTPStubs/wiki/Detailed-Integration-Instruction)._

> ### **Important Note**
`OHHTTPStubs` is designed to be used **in test/debug code only**.
**Don't link with it in production code when you compile your final application for the AppStore**.

> _Its code use a private API to build an `NSHTTPURLResponse`, which is not authorized by Apple in applications published on the AppStore.
So you will probably only link it with your Unit Tests target, or inside some `#if DEBUG`/`#endif` portions of your code._

## About `OHHTTPStubs` Unit Tests

`OHHTTPStubs` include some *Unit Tests*, and some of them test cases when using `OHHTTPStubs` with the [`AFNetworking`](https://github.com/AFNetworking/AFNetworking/) framework.
To implement those test cases, `AFNetworking` has been added as a _GIT submodule_ inside the "Unit Tests" folder.
This means that if you want to be able to run `OHHTTPStubs`' Unit Tests,
  you need to include submodules when cloning, by using the `--recursive` option:
  `git clone --recursive <this_repo_url> <destination_folder>`.
Alternatively if you didn't include the `--recursive` flag when cloning, you can use `git submodule init` and then `git submodule update`
on your already cloned working copy to initialize and fetch/update the submodules.

_This is only needed if you intend to run the `OHHTTPStubs` Unit Tests, to check the correct behavior of `OHHTTPStubs`
in conjunction with `AFNetworking`. If you only intend to directly use the `OHHTTPStubs`'s
produced library and will never run the `OHHTTPStubs` Unit Tests, the `AFNetworking` submodule is not needed at all._

## Change Log

The changelog is available [here in the dedicated wiki page](https://github.com/AliSoftware/OHHTTPStubs/wiki/ChangeLog).


## License and Credits

This project is brought to you by Olivier Halligon and is under MIT License

It has been inspired by [this article from InfiniteLoop.dk](http://www.infinite-loop.dk/blog/2011/09/using-nsurlprotocol-for-injecting-test-data/)
_(See also his [GitHub repository](https://github.com/InfiniteLoopDK/ILTesting))_

