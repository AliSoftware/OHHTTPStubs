OHHTTPStubs
===========

[![Platform](http://cocoapod-badges.herokuapp.com/p/OHHTTPStubs/badge.png)](http://cocoadocs.org/docsets/OHHTTPStubs)
[![Version](http://cocoapod-badges.herokuapp.com/v/OHHTTPStubs/badge.png)](http://cocoadocs.org/docsets/OHHTTPStubs)
[![Carthage Swift 3.0/3.1](https://img.shields.io/badge/Carthage-Swift%203.x-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/AliSoftware/OHHTTPStubs.svg?branch=master)](https://travis-ci.org/AliSoftware/OHHTTPStubs)
[![Language: Swift-2.3/3.0/3.1](https://img.shields.io/badge/Swift-2.3%2F3.0%2F3.1-orange.svg)](https://swift.org)

`OHHTTPStubs` is a library designed to stub your network requests very easily. It can help you:

* test your apps with **fake network data** (stubbed from file) and **simulate slow networks**, to check your application behavior in bad network conditions
* write **unit tests** that use fake network data from your fixtures.

It works with `NSURLConnection`, `NSURLSession`, `AFNetworking`, `Alamofire` or any networking framework that use Cocoa's URL Loading System.

[<img alt="Donate" src="https://www.paypalobjects.com/webstatic/mktg/merchant_portal/button/donate.en.png" height="32px">](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=TRTU3UEWEHV92 "Donate")

----

# Documentation & Usage Examples

`OHHTTPStubs` headers are fully documented using Appledoc-like / Headerdoc-like comments in the header files. You can also [read the **online documentation** here](http://cocoadocs.org/docsets/OHHTTPStubs).


## Basic example

<details>
<summary>In Objective-C</summary>

```objc
[OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
  return [request.URL.host isEqualToString:@"mywebservice.com"];
} withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
  // Stub it with our "wsresponse.json" stub file (which is in same bundle as self)
  NSString* fixture = OHPathForFile(@"wsresponse.json", self.class);
  return [OHHTTPStubsResponse responseWithFileAtPath:fixture
            statusCode:200 headers:@{@"Content-Type":@"application/json"}];
}];
```

</details>

<details open=1>
<summary>In Swift</summary>

This example is using the Swift helpers found in `OHHTTPStubsSwift.swift` provided by the `OHHTTPStubs/Swift` subspec.
 
```swift
stub(isHost("mywebservice.com")) { _ in
  // Stub it with our "wsresponse.json" stub file (which is in same bundle as self)
  let stubPath = OHPathForFile("wsresponse.json", type(of: self))
  return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
}
```

**Note**: if you're using `OHHTTPStubs`'s Swiftier API (`OHHTTPStubsSwift.swift` and the `Swift` subspec), you can also compose the matcher functions like this: `stub(isScheme("http") && isHost("myhost")) { … }`
</details>

## More examples & Help Topics
    
* For a lot more examples, see the dedicated "[Usage Examples](https://github.com/AliSoftware/OHHTTPStubs/wiki/Usage-Examples)" wiki page.
* The wiki also contain [some articles that can help you get started](https://github.com/AliSoftware/OHHTTPStubs/wiki) with (and troubleshoot if needed) `OHHTTPStubs`.

## Recording requests to replay them later

Instead of writing the content of the stubs you want to use manually, you can use tools like [SWHttpTrafficRecorder](https://github.com/capitalone/SWHttpTrafficRecorder) to record network requests into files. This way you can later use those files as stub responses.  
This tool can record all three formats that are supported by `OHHTTPStubs` (the `HTTPMessage` format, the simple response boby/content file, and the `Mocktail` format).

_(There are also other ways to perform a similar task, including using `curl -is <url> >foo.response` to generate files compatible with the `HTTPMessage` format, or using other network recording libraries similar to `SWHttpTrafficRecorder`)._

# Compatibility

* `OHHTTPStubs` is compatible with **iOS5+**, **OS X 10.7+**, **tvOS**.
* `OHHTTPStubs` also works with `NSURLSession` as well as any network library wrapping them.
* `OHHTTPStubs` is **fully compatible with Swift 2.2, 2.3, 3.0 and 3.1**.

_[Nullability annotations](https://developer.apple.com/swift/blog/?id=25) have also been added to the ObjC API to allow a cleaner API when used from Swift even if you don't use the dedicated Swift API wrapper provided by `OHHTTPStubsSwift.swift`._

<details>
<summary>Swift 2.2 users</summary>

If you're still building for Swift 2.2, you will have some `extraneous '_' in parameter` warnings. Those are normal: it's because the code has already done the transition to Swift 3 — which requires those `_` in parameters while Swift 2.2 didn't.  

You can safely ignore those warnings in Swift 2.2. See [SE-0046](https://github.com/apple/swift-evolution/blob/master/proposals/0046-first-label.md) for more info.
</details>

<details>
<summary>Carthage users using Swift 2.x</summary>

If you're using Carthage, we don't do Swift-2.3-specific branches anymore (too much maintenance work and most people have migrated already anyway) but if you still need Swift 2.3 compatibility, you can follow the tips in [the installation instructions below](#using-the-right-swift-version-for-your-project) to force Carthage to build this library with Swift 2.3.

</details>

# Installing in your projects

## CocoaPods

Using [CocoaPods](https://guides.cocoapods.org) is the recommended way.

* If you **intend to use `OHHTTPStubs` from Objective-C only**, add `pod 'OHHTTPStubs'` to your `Podfile`.
* If you **intend to use `OHHTTPStubs` from Swift**, add `pod 'OHHTTPStubs/Swift'` to your `Podfile` instead.

```ruby
pod 'OHHTTPStubs/Swift' # includes the Default subspec, with support for NSURLSession & JSON, and the Swiftier API wrappers
```

### All available subspecs

`OHHTTPStubs` is split into subspecs so that when using Cocoapods, you can get only what you need, no more, no less.

* The default subspec includes `NSURLSession`, `JSON`, and `OHPathHelpers`
* The `Swift` subspec adds the Swiftier API to that default subspec
* `HTTPMessage` and `Mocktail` are opt-in subspecs: list them explicitly if you need them
* `OHPathHelpers` doesn't depend on `Core` and can be used independently of `OHHTTPStubs` altogether

<details>
<summary>List of all the subspecs & their dependencies</summary>

Here's a list of which subspecs are included for each of the different lines you could use in your `Podfile`:

| Subspec                           | Core | NSURLSession | JSON | Swift | OHPathHelpers | HTTPMessage | Mocktail |
| --------------------------------- | :--: | :----------: | :--: | :---: | :-----------: | :---------: | :------: |
| `pod 'OHHTTPStubs'`               | ✅   | ✅           | ✅   |       | ✅            |             |          |
| `pod 'OHHTTPStubs/Default'`       | ✅   | ✅           | ✅   |       | ✅            |             |          |
| `pod 'OHHTTPStubs/Swift'`         | ✅   | ✅           | ✅   | ✅    | ✅            |             |          |
| `pod 'OHHTTPStubs/Core'`          | ✅   |              |      |       |               |             |          |
| `pod 'OHHTTPStubs/NSURLSession'`  | ✅   | ✅           |      |       |               |             |          |
| `pod 'OHHTTPStubs/JSON'`          | ✅   |              | ✅   |       |               |             |          |
| `pod 'OHHTTPStubs/OHPathHelpers'` |      |              |      |       | ✅            |             |          |
| `pod 'OHHTTPStubs/HTTPMessage'`   | ✅   |              |      |       |               | ✅          |          |
| `pod 'OHHTTPStubs/Mocktail'`      | ✅   |              |      |       |               |             | ✅       |

</details>

## Carthage

`OHHTTPStubs` is also be compatible with Carthage. Just add it to your `Cartfile`.

_Note: The `OHHTTPStubs.framework` built with Carthage will include **all** features of `OHHTTPStubs` turned on (in other words, all subspecs of the pod), including `NSURLSession` and `JSON` support, `OHPathHelpers`, `HTTPMessage` and `Mocktail` support, and the Swiftier API._

> Be warned that I don't personally use Carthage, so I won't be able to guarantee much help/support for it.

## Using the right Swift version for your project

`OHHTTPStubs` supports Swift 2.2 (Xcode 7), Swift 2.3 (Xcode 8), Swift 3.0 (Xcode 8+) and Swift 3.1 (Xcode 8.3+) 🎉 

Here are some details about the correct setup you need depending on how you integrated `OHHTTPStubs` into your project.

<details>
<summary><b>CocoaPods: nothing to do</b></summary>

If you use CocoaPods version [`1.1.0.beta.1`](https://github.com/CocoaPods/CocoaPods/releases/tag/1.1.0.beta.1) or later, then CocoaPods will compile `OHHTTPStubs` with the right Swift Version matching the one you use for your project automatically. You have nothing to do! 🎉

For more info, see [CocoaPods/CocoaPods#5540](https://github.com/CocoaPods/CocoaPods/pull/5540) and [CocoaPods/CocoaPods#5760](https://github.com/CocoaPods/CocoaPods/pull/5760).
</details>

<details>
<summary><b>Carthage: choose the right version</b></summary>

The project is set up with `SWIFT_VERSION=3.0` on `master`.

This means that the framework on `master` will build using:

* Swift 3.1 on Xcode 8.3
* Swift 3.0 on Xcode 8.2
* Swift 2.2/2.3 on Xcode 7.x.

We stopped doing Swift-2.3-specific branches (too much maintenance work), so if you want Carthage to build the framework with Swift 2.3 you can:

 * either use an older Xcode version
 * or use the previous version of `OHHTTPStubs` (5.2.3) — whose `master` branch uses `2.3`
 * or fork the repo just to change the `SWIFT_VERSION` build setting to `2.3`
 * or ask Carthage maintainers to [fix this issue](https://github.com/Carthage/Carthage/issues/1445) once and for all.

</details>

# Special Considerations

## Using OHHTTPStubs in your unit tests

`OHHTTPStubs` is ideal to write unit tests that normally would perform network requests. But if you use it in your unit tests, don't forget to:

* remove any stubs you installed after each test — to avoid those stubs to still be installed when executing the next Test Case — by calling `[OHHTTPStubs removeAllStubs]` in your `tearDown` method. [see this wiki page for more info](https://github.com/AliSoftware/OHHTTPStubs/wiki/Remove-stubs-after-each-test)
* be sure to wait until the request has received its response before doing your assertions and letting the test case finish (like for any asynchronous test). [see this wiki page for more info](https://github.com/AliSoftware/OHHTTPStubs/wiki/OHHTTPStubs-and-asynchronous-tests)

## Automatic loading

`OHHTTPStubs` is automatically loaded and installed (at the time the library is loaded in memory), both for:

* requests made using `NSURLConnection` or `[NSURLSession sharedSession]` — [thanks to this code](https://github.com/AliSoftware/OHHTTPStubs/blob/master/OHHTTPStubs/Sources/OHHTTPStubs.m#L107-L113)
* requests made using a `NSURLSession` that was created via `[NSURLSession sessionWithConfiguration:…]` and using either `[NSURLSessionConfiguration defaultSessionConfiguration]` or `[NSURLSessionConfiguration ephemeralSessionConfiguration]` configuration — thanks to [method swizzling](http://nshipster.com/method-swizzling/) done [here in the code](https://github.com/AliSoftware/OHHTTPStubs/blob/master/OHHTTPStubs/Sources/NSURLSession/OHHTTPStubs+NSURLSessionConfiguration.m).

If you need to disable (and re-enable) `OHHTTPStubs` — globally or per `NSURLSession` — you can use `[OHHTTPStubs setEnabled:]` / `[OHHTTPStubs setEnabled:forSessionConfiguration:]`.

## Known limitations

* `OHHTTPStubs` **can't work on background sessions** (sessions created using `[NSURLSessionConfiguration backgroundSessionConfiguration]`) because background sessions don't allow the use of custom `NSURLProtocols` and are handled by the iOS Operating System itself.
* `OHHTTPStubs` don't simulate data upload. The `NSURLProtocolClient` `@protocol` does not provide a way to signal the delegate that data has been **sent** (only that some has been loaded), so any data in the `HTTPBody` or `HTTPBodyStream` of an `NSURLRequest`, or data provided to `-[NSURLSession uploadTaskWithRequest:fromData:];` will be ignored, and more importantly, the `-URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:` delegate method will never be called when you stub the request using `OHHTTPStubs`.

_As far as I know, there's nothing we can do about those two limitations. Please let me know if you know a solution that would make that possible anyway._


## Submitting to the App Store

`OHHTTPStubs` **can be used** on apps submitted **on the App Store**. It does not use any private API and nothing prevents you from shipping it.

But you generally only use stubs during the development phase and want to remove your stubs when submitting to the App Store. So be careful to only include `OHHTTPStubs` when needed (only in your test targets, or only inside `#if DEBUG` sections, or by using [per-Build-Configuration pods](https://guides.cocoapods.org/syntax/podfile.html#pod)) to avoid forgetting to remove it when the time comes that you release for the App Store and you want your requests to hit the real network!



# License and Credits

This project and library has been created by Olivier Halligon ([@aligatr](https://twitter.com/aligatr) on Twitter) and is under the MIT License.

It has been inspired by [this article from InfiniteLoop.dk](https://web-beta.archive.org/web/20161219003951/http://www.infinite-loop.dk/blog/2011/09/using-nsurlprotocol-for-injecting-test-data/).

I would also like to thank:

* Sébastien Duperron ([@Liquidsoul](https://github.com/Liquidsoul)) for helping me maintaining this library, triaging and responding to issues and PRs
* Kevin Harwood ([@kcharwood](https://github.com/kcharwood)) for migrating the code to `NSInputStream`
* Jinlian Wang ([@JinlianWang](https://github.com/JinlianWang)) for adding Mocktail support
* and everyone else who contributed to this project on GitHub somehow.

If you want to support the development of this library, feel free to [<img alt="Donate" src="https://www.paypalobjects.com/webstatic/mktg/merchant_portal/button/donate.en.png" height="25px">](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=TRTU3UEWEHV92 "Donate"). Thanks to all contributors so far!
