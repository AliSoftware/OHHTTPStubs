OHHTTPStubs
===========

A class to stub network requests easily: test your apps with **fake network data** (stubbed from file) and **custom response times**.

`OHHTTPStubs` is very useful to write **Unit Tests** and return fake network data from your fixtures, or to **simulate slow networks** in order to check your application behavior in bad network conditions.
It works with `NSURLConnection`, `AFNetworking`, or any networking framework you chose to use.

[![Build Status](https://travis-ci.org/AliSoftware/OHHTTPStubs.png?branch=master)](https://travis-ci.org/AliSoftware/OHHTTPStubs)

----

* [Basic Usage](#basic-usage)
 * [How it works](#how-it-works)
 * [Stub all requests with some given NSData](#stub-all-requests-with-some-given-nsdata)
 * [Conditionally stub only certain requests](#conditionally-stub-only-certain-requests)
 * [Set request and response time](#set-request-and-response-time)
* [Detail of the `OHHTTPStubsResponse` methods](#detail-of-the-ohhttpstubsresponse-methods)
 * [Stub response given some NSData](#stub-response-given-some-nsdata)
 * [Stub response from a file](#stub-response-from-a-file)
 * [Respond with an error](#respond-with-an-error)
 * [Extension to use JSON Objects](#extension-to-use-json-objects)
 * [Extension to use full HTTP messages](#extension-to-use-full-http-messages)
* [Advanced Examples](#advanced-examples)
 * [Return a response depending on the request](#return-a-response-depending-on-the-request)
 * [Using download speed instead of responseTime](#using-download-speed-instead-of-responsetime)
 * [Stack multiple request handlers](#stack-multiple-request-handlers)
* [Installing in your projects](#installing-in-your-projects)
 * [Integrating using CocoaPods](#integrating-using-cocoapods)
 * [Integrating manually](#integrating-manually)
* [About OHHTTPStubs Unit Tests](#about-ohhttpstubs-unit-tests)
* [Change Log](#change-log)
* [License and Credits](#license-and-credits)

----

## Basic Usage

`OHHTTPStubs` is aimed to be very simple to use. It uses block to intercept outgoing requests and allow you to return your own data instead.

##### How it works

The principle is to call `stubRequestsPassingTest:withStubResponse:` to install your define stub responses and when to stub them.

Then for every request sent, whatever the framework used (`NSURLConnection`,
[`AFNetworking`](https://github.com/AFNetworking/AFNetworking/), or anything else):

* The block passed as first argument of `stubRequestsPassingTest:withStubResponse:` will be called to check if we need to stub this request.
* If this block returned anything that evaluates to YES, the block passed as second argument will be called to let you return an `OHHTTPStubsResponse` object, describing the fake response to return.

_(In practice, it uses the URL Loading System of Cocoa and a custom `NSURLProtocol` to intercept the requests and stub them)_

We will demonstrate multiple examples below.

##### Stub all requests with some given NSData

With the code below, every network request (because you returned YES in the first block) will return a stubbed response containing the data `"Hello World!"`:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES; // Stub ALL requests without any condition
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        // Stub all those requests with "Hello World!" string
        NSData* stubData = [@"Hello World!" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:nil];
    }];
     

##### Conditionally stub only certain requests

In practice, this is quite uncommon to stub ALL your outgoing network requests, especially with the same stub response. Instead, you may give the condition upon which the network requests will be stubbed. This is typically used in your Unit Tests to stub specific requests targeted to a given host or WebService.

With the code below, only requests to the `mywebservice.com` host will be stubbed. Requests to any other host will hit the real world:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mywebservice.com"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        // Stub it with our "wsresponse.json" stub file
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"wsresponse.json",nil)
                statusCode:200 headers:@{"Content-Type":@"text/json"}];
    }];

This example also demonstrate how to **easily return the content of a given file in your application bundle**.
This is useful if you have all your fixtures (stubbed responses for your Unit Tests) in your Xcode project linked with your Unit Test target.

> Note: You may even put all your fixtures in a custom bundle (let's call it Fixtures.bundle) to group them, simply link this bundle to your Unit Test target, and then use my helper macros macros to get it like this: `OHPathForFileInBundle(@"wsresponse.json",OHResourceBundle(@"Fixtures"))`.
_Of course, you are free to build your own file paths or define your own macros to ease your path construction :wink:_

##### Set request and response time

The `OHHTTPStubsResponse` you return can also contain timing information, like if `OHHTTPStubs` should simulate a latency by delaying the response or sending the data in small chunks during a given duration instead of all at a time.
_This is useful to simulate slow networks, for example, and to check that your user interface does not freeze in such occasions and that you though about displaying some activity indicators while waiting for your network responses, etc._

You may simply set the `requestTime` and `responseTime` of your `OHHTTPStubsReponse` to indicate this timing information, but an alternate, easiest way is to use `requestTime:response:` method that simply set them both and return the `OHHTTPStubsResponse` itself, so those calls can be chained, like this:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mywebservice.com"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithJSONObject:someDict statusCode:200 headers:nil]
                requestTime:1.0 responseTime:3.0];
    }];

`OHHTTPStubs` will wait `requestTime` before sending the `NSHTTPURLResponse` (and the first chunk of data), and then start sending chunks of the stub data regularly during `responseTime` so that after the given `responseTime` all the stub data is sent.
This simulates regular reception of some data dispatched during the `responseTime` like if the server took time sending the content of a large response.

At the end, you will only have the full content of your stub data after `requestTime+responseTime`, time after which the `completionHandler` block or `connectionDidFinishLoading:` delegate method of your `NSURLConnection` call — or the `completion` block of your `AFNetworking` call if you use [`AFNetworking`](https://github.com/AFNetworking/AFNetworking/) — will be called.

> Note that you can specify a network speed instead of a `responseTime` by using a negative value, whose absolute value expresses the desired speed to simulate in KB/s. `OHHTTPStubsResponse.h` provides some useful constants for such speeds, like `OHHTTPStubsDownloadSpeedEDGE` or `OHHTTPStubsDownloadSpeedWifi`.

This code also show how you can create a OHHTTPStubsReponse with a JSON object. `responseWithJSONObject:` will serialize the JSON object (`NSDictionary` in our example) and add the `"Content-Type: text/json"` header if not present already.


## Detail of the `OHHTTPStubsResponse` methods

The `OHHTTPStubsResponse` class, describing the fake response to return, exposes multiple commodity constructors:

##### Stub response given some NSData

    +(instancetype)responseWithData:(NSData*)data
                         statusCode:(int)statusCode
                            headers:(NSDictionary*)httpHeaders;

##### Stub response from a file

    +(instancetype)responseWithFileAtPath:(NSString*)fileName
                               statusCode:(int)statusCode
                                  headers:(NSDictionary*)httpHeaders;

You are encouraged to use the `OHPathForFileInBundle`, `OHPathForFileInDocumentsDir` and `OHResourceBundle` macros to build your file paths more easily.

##### Respond with an error

    +(id)responseWithError:(NSError*)error;

_(e.g. you could use an error like `[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]` to simulate an absence of network connection)_


##### Extension to use JSON Objects

This commodity method is defined in the `OHHTTPStubsResponse+JSON` category.

    +(instancetype)responseWithJSONObject:(id)jsonObject
                                statusCode:(int)statusCode
                                   headers:(NSDictionary *)httpHeaders;

##### Extension to use full HTTP messages

These commodity constructors are defined in the `OHHTTPStubs+HTTPMessage` category.

You can dump entire responses using `curl -is [URL]` on the command line. These include all HTTP headers, the response status code and the response body in one file. Use then this method to load them into a `OHHTTPStubsResponse` object:

    +(OHHTTPStubsResponse*)responseWithHTTPMessageData:(NSData*)responseData;

You may also add a bundle (e.g. `APIResponses.bundle`) to your test target and put all HTTP message dumps (using `curl -is [URL]`) of your responses in there and give them a `.response` extension. Using this method allows you to address them by name. You can also put your dumped responses in a directory structure and address them that way (e.g. using `users/me` as the response name would look for a file `me.response` inside the `users` folder in the bundle you passed in).

    +(OHHTTPStubsResponse*)responseNamed:(NSString*)responseName
                              fromBundle:(NSBundle*)bundle;

## Advanced Examples

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
       return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(basename) statusCode:200 headers:@"text/json"];
     }];


### Using download speed instead of responseTime

When building the `OHHTTPStubsResponse` object, you can specify a response time (in seconds) so that the sending of the fake response will be postponed. This allows you to simulate a slow network for example.

If you specify a negative value for the responseTime parameter, instead of being interpreted as a time in seconds, it will be interpreted as a download speed in KBytes/s. In that case, the response time will be computed using the size of the response's data to simulate the indicated download speed.

The `OHHTTPStubsResponse` header defines some constants for standard download speeds:
* `OHHTTPStubsDownloadSpeedGPRS`   :    56 kbps (7 KB/s)
* `OHHTTPStubsDownloadSpeedEDGE`   :   128 kbps (16 KB/s)
* `OHHTTPStubsDownloadSpeed3G`     :  3200 kbps (400 KB/s)
* `OHHTTPStubsDownloadSpeed3GPlus` :  7200 kbps (900 KB/s)
* `OHHTTPStubsDownloadSpeedWifi`   : 12000 kbps (1500 KB/s)


### Stack multiple request handlers

You can call `stubRequestsPassingTest:withStubResponse:` multiple times. It will just add the response handlers in an internal list of handlers.

_This may be useful to install different stubs in different classes (say different UIViewControllers) and various places in your application, or to separate different stubs and stubbing conditions (like some stubs for images and other stubs for JSON files) more easily. See the `OHHTTPStubsDemo` project for a typical example._

When a network request is performed by the system, the response handlers are called in the reverse order that they have been added, the last added handler having priority over the first added ones.
The first handler that returns YES for the first parameter of `stubRequestsPassingTest:withStubResponse:` is then used to reply to the request.

* You can remove the latest added handler with the `removeLastRequestHandler` method, and all handlers with the `removeAllRequestHandlers` method.
* You can also remove any given handler with the `removeRequestHandler:` method. This method takes as a parameter the object returned by `stubRequestsPassingTest:withStubResponse:`.
_Note that this returned object is already retained by `OHHTTPStubs` while the stub is installed, so you may keep it in a `__weak` variable (no need to keep a `__strong` reference)._



## Installing in your projects

> **Warning: Be careful anyway to include `OHHTTPStubs` only in your test targets, or only use it in `#if DEBUG` portions, so that its code is not included in your release for the AppStore !**

_Note: `OHHTTPStibs` uses APIs that were introduced in iOS5+, so it needs a deployment target of iOS5 minimum._

### Integrating using CocoaPods

[CocoaPods](http://cocoapods.org/) is the easiest way to add third-party libraries like `OHHTTPStubs` in your projects.

`OHHTTPStubs` is referenced in [`CocoaPods`](https://github.com/CocoaPods/Specs/tree/master/OHHTTPStubs), so you simply have to add `pod 'OHHTTPStubs'` to your Podfile!

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

It has been inspired by [this article from InfiniteLoop.dk](http://www.infinite-loop.dk/blog/2011/09/using-nsurlprotocol-for-injecting-test-data/).
I would also like to thank to @kcharwood for its contribution, and everyone who contributed to this project on GitHub.


