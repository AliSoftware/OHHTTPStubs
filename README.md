OHHTTPStubs
===========

A class to stub network requests easily: test your apps with **fake network data** (stubbed from file) and **custom response times**.

`OHHTTPStubs` is very useful to write **Unit Tests** and return fake network data from your fixtures, or to **simulate slow networks** in order to check your application behavior in bad network conditions.
It works with `NSURLConnection`, `AFNetworking`, or any networking framework you chose to use.

[![Build Status](https://travis-ci.org/AliSoftware/OHHTTPStubs.png?branch=master)](https://travis-ci.org/AliSoftware/OHHTTPStubs)

----

* [How it works](#how-it-works)
* [Documentation](#documentation)
* [Usage examples](#usage-examples)
  * [Stub all requests with some given NSData](#stub-all-requests-with-some-given-nsdata)
  * [Stub only requests to your WebService](#stub-only-requests-to-your-webservice)
  * [Set request and response time](#set-request-and-response-time)
  * [Simulate a down network](#simulate-a-down-network)
* [Advanced Usage](#advanced-usage)
  * [Use macros to build your fixtures path](#use-macros-to-build-your-fixtures-path)
  * [Using download speed instead of responseTime](#using-download-speed-instead-of-responsetime)
  * [Stack multiple stubs and remove installed stubs](#stack-multiple-stubs-and-remove-installed-stubs)
  * [Name your stubs and log their activation](#name-your-stubs-and-log-their-activation)
  * [OHHTTPStubs and NSURLSession](#ohhttpstubs-and-nsurlsession)
* [Installing in your projects](#installing-in-your-projects)
* [About OHHTTPStubs Unit Tests](#about-ohhttpstubs-unit-tests)
* [Change Log](#change-log)
* [License and Credits](#license-and-credits)

----

## How it works

Using `OHHTTPStubs` is as simple as calling `stubRequestsPassingTest:withStubResponse:` to tell which requests you want to stub and what data you want to respond with.

For every request sent to the network, whatever the framework used (`NSURLConnection`,
[`AFNetworking`](https://github.com/AFNetworking/AFNetworking/), …):

* The block passed as first argument of `stubRequestsPassingTest:withStubResponse:` will be called to check if we need to stub this request.
* If the return value of this block is YES, the block passed as second argument will be called to let you return an `OHHTTPStubsResponse` object, describing the fake response to return.

_(In practice, it uses the URL Loading System of Cocoa and a custom `NSURLProtocol` to intercept the requests and stub them)_


## Documentation

`OHHTTPStubs` headers are fully documented using Appledoc-like / Headerdoc-like comments in the header files.
When you [install it using CocoaPods](#installing-in-your-projects), you will get a docset for free installed in your Xcode Organizer.

Don't hesitate to take a look into `OHHTTPStubsResponse.h`, `OHHTTPStubsResponse+JSON.h` and `OHHTTPStubsResponse.HTTPMessage.h` to see all the commodity constructors, constants and macros available.


## Usage examples


### Stub all requests with some given NSData

With the code below, every network request (because you returned YES in the first block) will return a stubbed response containing the data `"Hello World!"`:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES; // Stub ALL requests without any condition
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        // Stub all those requests with "Hello World!" string
        NSData* stubData = [@"Hello World!" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:nil];
    }];
     

### Stub only requests to your WebService

This is typically useful in your Unit Tests to only stub specific requests targeted to a given host or WebService, for example.

With the code below, only requests to the `mywebservice.com` host will be stubbed. Requests to any other host will hit the real world:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mywebservice.com"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        // Stub it with our "wsresponse.json" stub file
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"wsresponse.json",nil)
                statusCode:200 headers:@{@"Content-Type":@"text/json"}];
    }];

This example also demonstrate how to **easily return the content of a given file in your application bundle**.
This is useful if you have all your fixtures (stubbed responses for your Unit Tests) in your Xcode project linked with your Unit Test target.

> Note: You may even put all your fixtures in a custom bundle (let's call it Fixtures.bundle) and then use the helper macros to get it with `OHPathForFileInBundle(@"wsresponse.json",OHResourceBundle(@"Fixtures"))`.

### Set request and response time

You can simulate a slow network by setting the `requestTime` and `responseTime` of your `OHHTTPStubsResponse`.
_This is useful to check that your user interface does not freeze and that you have all your activity indicators working while waiting for responses in bad network conditions._

You may use the commoidty chainable setters  `responseTime:` and `requestTime:responseTime:` to set those values and easily chain method calls:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"mywebservice.com"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [[OHHTTPStubsResponse responseWithJSONObject:someDict statusCode:200 headers:nil]
                requestTime:1.0 responseTime:3.0];
    }];

`OHHTTPStubs` will wait `requestTime` before sending the `NSHTTPURLResponse`, and then start sending chunks of the stub data regularly during the period of `responseTime`, to simulate the slow network.

At the end, you will only have the full content of your stub data after `requestTime+responseTime`, time after which the `completion` block or `connectionDidFinishLoading:` delegate method will be called.

> You can specify a **network speed** instead of a `responseTime` by using a negative value. [See below](#using-download-speed-instead-of-responsetime).

### Simulate a down network

You may also return a network error for your stub. For example, you can easily simulate an absence of network connection like this:

    [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil]];


## Advanced Usage

### Use macros to build your fixtures path

`OHHTTPStubsResponse.h` includes a useful set of macros to build a path to your fixtures easily, like `OHPathForFileInBundle`, `OHPathForFileInDocumentsDir` and `OHResourceBundle`. You are encouraged to use them to build your path more easily.

> Especially, they use `[NSBundle bundleForClass:self.class]` to reference your app bundle (and not `[NSBundle mainBundle]` as one may think), so that they still work with OCUnit and XCTestKit when unit-testing your app in the Simulator.

### Using download speed instead of responseTime

When building the `OHHTTPStubsResponse` object, you can specify a response time (in seconds) so that the sending of the fake response will be spread over time. This allows you to simulate a slow network for example. ([see "Set request and response time"](#set-request-and-response-time))

If you specify a negative value for the responseTime parameter, instead of being interpreted as a time in seconds, it will be interpreted as a download speed in KBytes/s. In that case, the response time will be computed using the size of the response's data to simulate the indicated download speed.

The `OHHTTPStubsResponse` header defines some constants for standard download speeds:

```
OHHTTPStubsDownloadSpeedGPRS   =    -7 =    7 KB/s =    56 kbps
OHHTTPStubsDownloadSpeedEDGE   =   -16 =   16 KB/s =   128 kbps
OHHTTPStubsDownloadSpeed3G     =  -400 =  400 KB/s =  3200 kbps
OHHTTPStubsDownloadSpeed3GPlus =  -900 =  900 KB/s =  7200 kbps
OHHTTPStubsDownloadSpeedWifi   = -1500 = 1500 KB/s = 12000 kbps
```

Example:

    return [[OHHTTPStubsResponse responseWithData:nil statusCode:400 headers:nil]
            responseTime:OHHTTPStubsDownloadSpeed3G];



### Stack multiple stubs and remove installed stubs

* You can call `stubRequestsPassingTest:withStubResponse:` multiple times. It will just add the stubs in an internal list of stubs.

_This may be useful to install different stubs in various places in your code, or to separate different stubbing conditions more easily. See the `OHHTTPStubsDemo` project for a typical example._

When a network request is performed by the system, the **stubs are called in the reverse order that they have been added**, the last added stub having priority over the first added ones.
The first stub that returns YES for the first parameter of `stubRequestsPassingTest:withStubResponse:` is then used to reply to the request.

* You can remove any given stub with the `removeStub:` method. This method takes as a parameter the `id<OHHTTPStubsDescriptor>` object returned by `stubRequestsPassingTest:withStubResponse:` _(Note: this returned object is already retained by `OHHTTPStubs` while the stub is installed, so there is no need to keep a `__strong` reference to it)_.
* You can remove the latest added stub with the `removeLastStub` method.
* You can also remove all stubs at once with the `removeAllStubs` method.

This last one is useful when using `OHHTTPStubs` in your Unit Tests, to remove all installed stubs at the end of each of your test case to avoid stubs installed in one test case to be still installed for the next test case.

    - (void)tearDown
    {
        [OHHTTPStubs removeAllStubs];
    }

### Name your stubs and log their activation

You can add a name of your choice to your stubs. The only purpose of this is to easily identify your stubs for debugging, like when displaying them in your console.

    id<OHHTTPStubsDescriptor> stub = [OHHTTPStubs stubRequestsPassingTest:... withStubResponse:...];
    stub.name = @"Stub for text files";
   
You can even imagine applying the `.name = ...` affectation directly if you don't need to use the returned `id<OHHTTPStubsDescriptor>` otherwise:

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
       ...
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
       ...
    }].name = @"Stub for text files";

You can then list all the installed stubs using `[OHHTTPStubs allStubs]`, which return an array of `id<OHHTTPStubsDescriptor>` objects so you can display their `name` on the console. This is useful to check that you didn't forget to remove some previous stubs that are still installed for example.

You can also setup a block to execute each time a request has been stubbed, using `onStubActivation:` method, typically to log the stub being used for each request:

    [OHHTTPStubs onStubActivation:^(NSURLRequest *request, id<OHHTTPStubsDescriptor> stub) {
        NSLog(@"%@ stubbed by %@", request.URL, stub.name);
    }];

### OHHTTPStubs and NSURLSession

`OHHTTPStubs` use a custom private `NSURLProtocol` to intercept its requests.

`OHHTTPStubs` is automatically enabled by default, both for:

* requests made using `NSURLConnection` or `[NSURLSession sharedSession]` _(that are based on `[NSURLProtocol registerProtocol:]` to look for custom protocols for every requests)_, because this protocol is installed as soon as you use the `OHHTTPStubs` class _(installed in the `+initialize` method)_
* requests made using a `NSURLSession` created with a `NSURLSessionConfiguration` and `[NSURLSession sessionWithConfiguration:]` _(thanks to method swizzling that insert the private protocol used by `OHHTTPStubs` into the `protocolClasses` of `[NSURLSessionConfiguration defaultSessionConfiguration]` and `[NSURLSessionConfiguration ephemeralSessionConfiguration]` automagically)_

> Note however that `OHHTTPStubs` **can't work on background sessions** (sessions created using `[NSURLSessionConfiguration backgroundSessionConfiguration]`) because background sessions don't allow the use of custom `NSURLProtocols`. There's nothing we can do about it, sorry.

If you need to disable (and re-enable) `OHHTTPStubs` globally or per session, you can use:

* `[OHHTTPStubs setEnabled:]` for `NSURLConnection`/`[NSURLSession sharedSession]`-based requests
* `[OHHTTPStubs setEnabled:forSessionConfiguration:]` for requests sent on a session created using `[NSURLSession sessionWithConfiguration:...]`

_There is generally no need to explicitly call `setEnabled:` or `setEnabled:forSessionConfiguration:` using `YES` as this is the default._

----

## Installing in your projects

[CocoaPods](http://cocoapods.org/) is the easiest way to add third-party libraries like `OHHTTPStubs` in your projects. Simply add `pod 'OHHTTPStubs'` to your `Podfile` and you are done.

_Note: `OHHTTPStubs` needs iOS5 minimum._

> **Warning: Be careful anyway to include `OHHTTPStubs` only in your test targets, or only use it in `#if DEBUG` portions, so that its code is not included in your release for the AppStore !**

In case you don't want to use CocoaPods (but you should!!!), the `OHHTTPStubs` project is provided as a Xcode project that generates a static library, so simply add its xcodeproj to your workspace and link your app against the `libOHHTTPStubs.a` library. See [here](https://github.com/AliSoftware/OHHTTPStubs/wiki/Detailed-Integration-Instruction) for detailed instructions.

_PS: If you get an "unrecognised selector sent to instance" runtime error, make sure that the project you want to link with `OHHTTPStubs` has the `-ObjC` flag in its "Other Linker Flags" (`OTHER_LDFLAGS`) build setting (this is normally the default in projects created in latest versions of Xcode). [See the Apple doc for more details](https://developer.apple.com/library/mac/qa/qa1490/_index.html)._

## About `OHHTTPStubs` Unit Tests

If you want to be able to run `OHHTTPStubs`' Unit Tests, be sure you cloned the [`AFNetworking`](https://github.com/AFNetworking/AFNetworking/) submodule (by using the `--recursive` option when cloning your repo, or using `git submodule init` and `git submodule update`) as it is used by some of `OHHTTPStubs` unit tests.

Every contribution to add more unit tests is welcome.

## Change Log

The changelog is available [here in the dedicated wiki page](https://github.com/AliSoftware/OHHTTPStubs/wiki/ChangeLog).


## License and Credits

This project and library has been created by Olivier Halligon (@AliSoftware) and is under the MIT License.

It has been inspired by [this article from InfiniteLoop.dk](http://www.infinite-loop.dk/blog/2011/09/using-nsurlprotocol-for-injecting-test-data/).
I would also like to thank to @kcharwood for its contribution, and everyone who contributed to this project on GitHub.
