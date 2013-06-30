OHHTTPStubs
===========

A class to stub network requests easily: test your apps with fake network data (stubbed from file) and custom response time

* [Basic Usage](#basic-usage)
* [The `OHHTTPStubsResponse` object](#the-ohhttpstubsresponse-object)
* [Advanced Usage](#advanced-usage)
 * [Return a response depending on the request](#return-a-response-depending-on-the-request)
 * [Using download speed instead of responseTime](#using-download-speed-instead-of-responsetime)
 * [Stack multiple request handlers](#stack-multiple-request-handlers)
* [Complete Examples](#complete-examples)
* [Installing in your projects](#installing-in-your-projects)
 * [Private API Warning](#private-api-warning)
 * [Integrating using CocoaPods](#integrating-using-cocoapods)
 * [Integrating manually](#integrating-manually)
* [About OHHTTPStubs Unit Tests](#about-ohhttpstubs-unit-tests)
* [Change Log](#change-log)
* [License and Credits](#license-and-credits)

----

## Basic Usage

This is aimed to be very simple to use. It uses block to intercept outgoing requests and allow you to
return data from a file instead.

##### This is the most simple way to use it:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES; // Stub ALL requests without any condition
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        // Stub all those requests with our "response.json" stub file
        return [OHHTTPStubsResponse responseWithFile:@"response.json" contentType:@"text/json" responseTime:2.0];
    }];
     
With this code, every network request will return a stubbed response containing the content of the `"response.json"` file (which must be in your bundle)
with a `"Content-Type"` header of `"text/json"` in the HTTP response, after 2 seconds.

##### We can also conditionally stub only certain requests, like this:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        // Only stub requests to "*.json" files
        return [request.URL.absoluteString.lastPathComponent.pathExtension isEqualToString:@"json"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        // Stub it with our "response.json" stub file
        return [OHHTTPStubsResponse responseWithFile:@"response.json" contentType:@"text/json" responseTime:2.0];
    }];

This code will only stub requests ending with ".json", and in such case return the content of the corresponding file in your bundle. Every other network request (not ending with ".json") will hit the real world.

##### How it works

For every request sent, whatever the framework used (`NSURLConnection`,
[`AFNetworking`](https://github.com/AFNetworking/AFNetworking/), or anything else):

* The block passed as first argument of `stubRequestsPassingTest:withStubResponse:` will be called to check if we need to stub this request.
* If this block returned YES, the block passed as second argument will be called to let you return an `OHHTTPStubsResponse` object, describing the fake response to return.

_(In practice, it uses the URL Loading System of Cocoa and a custom `NSURLProtocol` to intercept the requests and stub them)_


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

##### Using a HTTP message to define a response

    +(OHHTTPStubsResponse*)responseWithHTTPMessageData:(NSData*)responseData
                                          responseTime:(NSTimeInterval)responseTime;

You can dump entire responses using `curl -is [URL]` on the command line. These include all HTTP headers, the response status code and the response body in one file. Use this initializer to load them into a `OHHTTPStubsResponse` object.

##### Conveniently loading HTTP messages

    +(OHHTTPStubsResponse*)responseNamed:(NSString*)responseName
                              fromBundle:(NSBundle*)bundle
                            responseTime:(NSTimeInterval)responseTime;

Add a bundle (e.g. `APIResponses.bundle`) to your test target and put all HTTP message dumps (using `curl -is [URL]`) of your responses in there and give them a `.response` extension. Using this method allows you to address them by name. You can also put your dumped responses in a directory structure and address them that way (e.g. using `users/me` as the response name would look for a file `me.response` inside the `users` folder in the bundle you passed in).
             
##### To respond with an error instead of a success

    +(id)responseWithError:(NSError*)error;

_(e.g. you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]`)_


## Advanced Usage

### Return a response depending on the request

Of course, and that's the main reason this is implemented with blocks, you can do whatever you need in the block implementation. This includes checking the request URL to see if you want to return a stub or not, and pick the right file according to the requested URL.

Example:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request)
     {
       NSString* basename = request.URL.absoluteString.lastPathComponent;
       return [basename.pathExtension isEqualToString:@"json"]; // Only stub requests to *.json files
     } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
         NSString* basename = request.URL.absoluteString.lastPathComponent;
         // Stub with the "*.json" file of the same name in your app bundle
         return [OHHTTPStubsResponse responseWithFile:basename contentType:@"text/json" responseTime:2.0];
     }];


### Using download speed instead of responseTime

When building the `OHHTTPStubsResponse` object, you can specify a response time (in seconds) so that the sending of the fake response will be postponed. This allows you to simulate a slow network for example.

If you specify a negative value for the responseTime parameter, instead of being interpreted as a time in seconds, it will be interpreted as a download speed in KBytes/s.
In that case, the response time will be computed using the size of the response's data to simulate the indicated download speed.

The `OHHTTPStubsResponse` header defines some constants for standard download speeds:
* `OHHTTPStubsDownloadSpeedGPRS`   :    56 kbps (7 KB/s)
* `OHHTTPStubsDownloadSpeedEDGE`   :   128 kbps (16 KB/s)
* `OHHTTPStubsDownloadSpeed3G`     :  3200 kbps (400 KB/s)
* `OHHTTPStubsDownloadSpeed3GPlus` :  7200 kbps (900 KB/s)
* `OHHTTPStubsDownloadSpeedWifi`   : 12000 kbps (1500 KB/s)


### Stack multiple request handlers

You can call `stubRequestsPassingTest:withStubResponse:` multiple times.
It will just add the response handlers in an internal list of handlers.

When a network request is performed by the system, the response handlers are called in the reverse order that they have been added, the last added handler having priority over the first added ones.
The first handler that returns YES for the first parameter of `stubRequestsPassingTest:withStubResponse:` is then used to reply to the request.

_This may be useful to install different stubs in different classes (say different UIViewControllers) and various places in your application, or to separate different stubs and stubbing conditions (like some stubs for images and other stubs for JSON files) more easily. See the `OHHTTPStubsDemo` project for a typical example._

You can remove the latest added handler with the `removeLastRequestHandler` method, and all handlers with the `removeAllRequestHandlers` method.

You can also remove any given handler with the `removeRequestHandler:` method.
This method takes as a parameter the object returned by `stubRequestsPassingTest:withStubResponse:`.
_Note that this returned object is already retained by `OHHTTPStubs` while the stub is installed, so you may keep it in a `__weak` variable (no need to keep a `__strong` reference)._



## Complete examples

Here is another example code below that uses the various techniques explained above.
For a complete Xcode projet, see the `OHHTTPStubsDemo.xcworkspace` project in the repository.


    NSArray* stubs = [NSArray arrayWithObjects:@"file1", @"file2", nil];
                           
    [OHHTTPStubs stubRequestPassingTest:^OHHTTPStubsResponse*(NSURLRequest *request) {
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

### Private API Warning

`OHHTTPStubs` is designed to be used **in test/debug code only**.
**Don't link with it in production code when you compile your final application for the AppStore**.

> _Its code use a private API to build an `NSHTTPURLResponse`, which is not authorized by Apple in applications published on the AppStore.
So you will probably only link it with your Unit Tests target, or inside some `#if DEBUG`/`#endif` portions of your code._

### Integrating using CocoaPods

`OHHTTPStubs` is referenced in [`CocoaPods`](https://github.com/CocoaPods/Specs/tree/master/OHHTTPStubs), so if you use [CocoaPods](http://cocoapods.org/) you can simply add `pod OHHTTPStubs` to your Podfile.

_Be careful anyway to include it only in your test targets, or only use its symbols in `#if DEBUG` portions, so that its code (and the private API it uses) is not included in your release for the AppStore, as explained above._

### Integrating manually

In case you don't want to use CocoaPods, the `OHHTTPStubs` project is provided as a Xcode project that generates a static library, so that you can also easily add its xcodeproj to your workspace and link your app against the `libOHHTTPStubs.a` library. See [the detailed instructions here](https://github.com/AliSoftware/OHHTTPStubs/wiki/Detailed-Integration-Instruction) for more info.


## About `OHHTTPStubs` Unit Tests

`OHHTTPStubs` include some *Unit Tests*, and some of them test cases when using `OHHTTPStubs` with the [`AFNetworking`](https://github.com/AFNetworking/AFNetworking/) framework.
To implement those test cases, `AFNetworking` has been added as a _GIT submodule_ inside the "Unit Tests" folder.
This means that if you want to be able to run `OHHTTPStubs`' Unit Tests, you need to include submodules when cloning, by using the `--recursive` option:
  `git clone --recursive <this_repo_url> <destination_folder>`.
Alternatively if you didn't include the `--recursive` flag when cloning, you can use `git submodule init` and then `git submodule update` on your already cloned working copy to initialize and fetch/update the submodules.

_This is only needed if you intend to run the `OHHTTPStubs` Unit Tests, to check the correct behavior of `OHHTTPStubs` in conjunction with `AFNetworking`. If you only intend to directly use the `OHHTTPStubs`'s produced library and will never run the `OHHTTPStubs` Unit Tests, the `AFNetworking` submodule is not needed at all._

## Change Log

The changelog is available [here in the dedicated wiki page](https://github.com/AliSoftware/OHHTTPStubs/wiki/ChangeLog).


## License and Credits

This project is brought to you by Olivier Halligon and is under MIT License

It has been inspired by [this article from InfiniteLoop.dk](http://www.infinite-loop.dk/blog/2011/09/using-nsurlprotocol-for-injecting-test-data/)

