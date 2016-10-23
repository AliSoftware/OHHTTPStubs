//
//  SwiftHelpersTests.swift
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 20/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation
import XCTest
@testable import OHHTTPStubs

#if swift(>=3.0)
#else
#if swift(>=2.2)
    extension SequenceType {
        private func enumerated() -> EnumerateSequence<Self> {
            return enumerate()
        }
    }

    extension NSMutableURLRequest {
        override var httpMethod: String? {
            get {
                return HTTPMethod
            }
            set(method) {
                self.HTTPMethod = method!
            }
        }
    }
#endif
#endif

class SwiftHelpersTests : XCTestCase {

  func testHTTPMethod() {
    let methods = ["GET", "PUT", "PATCH", "POST", "DELETE", "FOO"]
    let matchers = [isMethodGET(), isMethodPUT(), isMethodPATCH(), isMethodPOST(), isMethodDELETE()]

    for (idxMethod, method) in methods.enumerated() {
#if swift(>=3.0)
      var req = URLRequest(url: URL(string: "foo://bar")!)
#else
      let req = NSMutableURLRequest(URL: NSURL(string: "foo://bar")!)
#endif
      req.httpMethod = method
      for (idxMatcher, matcher) in matchers.enumerated() {
        let expected = idxMethod == idxMatcher // expect to be true only if indexes match
        XCTAssert(matcher(req) == expected, "Function is\(methods[idxMatcher])() failed to test request with HTTP method \(method).")
      }
    }
  }
  
  func testIsScheme() {
    let matcher = isScheme("foo")
    
    let urls = [
      "foo:": true,
      "foo://": true,
      "foo://bar/baz": true,
      "bar://": false,
      "bar://foo/": false,
      "foobar://": false
    ]
    
    for (url, result) in urls {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif
      XCTAssert(matcher(req) == result, "isScheme(\"foo\") matcher failed when testing url \(url)")
    }
  }
  
  func testIsHost() {
    let matcher = isHost("foo")
    
    let urls = [
      "foo:": false,
      "foo://": false,
      "foo://bar/baz": false,
      "bar://foo": true,
      "bar://foo/baz": true,
    ]
    
    for (url, result) in urls {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif
      XCTAssert(matcher(req) == result, "isHost(\"foo\") matcher failed when testing url \(url)")
    }
  }

  func testIsPath_absoluteURL() {
    testIsPath("/foo/bar/baz", isAbsoluteMatcher: true)
  }

  func testIsPath_relativeURL() {
    testIsPath("foo/bar/baz", isAbsoluteMatcher: false)
  }
  
  func testIsPath(_ path: String, isAbsoluteMatcher: Bool) {
    let matcher = isPath(path)
    
    let urls = [
      // Absolute URLs
      "scheme:": false,
      "scheme://": false,
      "scheme://foo/bar/baz": false,
      "scheme://host/foo/bar": false,
      "scheme://host/foo/bar/baz": isAbsoluteMatcher,
      "scheme://host/foo/bar/baz?q=1": isAbsoluteMatcher,
      "scheme://host/foo/bar/baz#anchor": isAbsoluteMatcher,
      "scheme://host/foo/bar/baz;param": isAbsoluteMatcher,
      "scheme://host/foo/bar/baz/wizz": false,
      "scheme://host/path#/foo/bar/baz": false,
      "scheme://host/path?/foo/bar/baz": false,
      "scheme://host/path;/foo/bar/baz": false,
      // Relative URLs
      "foo/bar/baz": !isAbsoluteMatcher,
      "foo/bar/baz?q=1": !isAbsoluteMatcher,
      "foo/bar/baz#anchor": !isAbsoluteMatcher,
      "foo/bar/baz;param": !isAbsoluteMatcher,
      "foo/bar/baz/wizz": false,
      "path#/foo/bar/baz": false,
      "path?/foo/bar/baz": false,
      "path;/foo/bar/baz": false,
    ]
    
    for (url, result) in urls {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif
      let p = req.url?.path
      print("URL: \(url) -> Path: \(p)")
      XCTAssert(matcher(req) == result, "isPath(\"\(path)\" matcher failed when testing url \(url)")
    }
  }

  func testPathStartsWith_absoluteURL() {
    testPathStartsWith("/foo/bar", isAbsoluteMatcher: true)
  }

  func testPathStartsWith_relativeURL() {
    testPathStartsWith("foo/bar", isAbsoluteMatcher: false)
  }

  func testPathStartsWith(_ path: String, isAbsoluteMatcher: Bool) {
    let matcher = pathStartsWith(path)

    let urls = [
      // Absolute URLs
      "scheme:": false,
      "scheme://": false,
      "scheme://foo/bar/baz": false,
      "scheme://host/foo/bar": isAbsoluteMatcher,
      "scheme://host/foo/bar/baz": isAbsoluteMatcher,
      "scheme://host/foo/bar?q=1": isAbsoluteMatcher,
      "scheme://host/foo/bar#anchor": isAbsoluteMatcher,
      "scheme://host/foo/bar;param": isAbsoluteMatcher,
      "scheme://host/path/foo/bar/baz": false,
      "scheme://host/path#/foo/bar/baz": false,
      "scheme://host/path?/foo/bar/baz": false,
      "scheme://host/path;/foo/bar/baz": false,
      // Relative URLs
      "foo/bar": !isAbsoluteMatcher,
      "foo/bar/baz": !isAbsoluteMatcher,
      "foo/bar?q=1": !isAbsoluteMatcher,
      "foo/bar#anchor": !isAbsoluteMatcher,
      "foo/bar;param": !isAbsoluteMatcher,
      "path/foo/bar/baz": false,
      "path#/foo/bar/baz": false,
      "path?/foo/bar/baz": false,
      "path;/foo/bar/baz": false,
    ]

    for (url, result) in urls {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif
      let p = req.url?.path
      print("URL: \(url) -> Path: \(p)")
      XCTAssert(matcher(req) == result, "pathStartsWith(\"\(path)\" matcher failed when testing url \(url)")
    }
  }
  
  func testIsExtension() {
    let matcher = isExtension("txt")
    
    let urls = [
      "txt:": false,
      "txt://": false,
      "txt://txt/txt/txt": false,
      "scheme://host/foo/bar.png": false,
      "scheme://host/foo/bar.txt": true,
      "scheme://host/foo/bar.txt?q=1": true,
      "scheme://host/foo/bar.baz?q=wizz.txt": false,
    ]
    
    for (url, result) in urls {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif
      XCTAssert(matcher(req) == result, "isExtension(\"txt\") matcher failed when testing url \(url)")
    }
    
  }
  @available(iOS 8.0, OSX 10.10, *)
  func testContainsQueryParams() {
    let params: [String: String?] = ["q":"test", "lang":"en", "empty":"", "flag":nil]
    let matcher = containsQueryParams(params)
    
    let urls = [
      "foo://bar": false,
      "foo://bar?q=test": false,
      "foo://bar?lang=en": false,
      "foo://bar#q=test&lang=en&empty=&flag": false,
      "foo://bar#lang=en&empty=&flag&q=test": false,
      "foo://bar;q=test&lang=en&empty=&flag": false,
      "foo://bar;lang=en&empty=&flag&q=test": false,
      
      "foo://bar?q=test&lang=en&empty=&flag": true,
      "foo://bar?lang=en&flag&empty=&q=test": true,
      "foo://bar?q=test&lang=en&empty=&flag#anchor": true,
      "foo://bar?q=test&lang=en&empty&flag": false, // key "empty" with no value is matched against nil, not ""
      "foo://bar?q=test&lang=en&empty=&flag=": false, // key "flag" with empty value is matched against "", not nil
      "foo://bar?q=en&lang=test&empty=&flag": false, // param keys and values mismatch
      "foo://bar?q=test&lang=en&empty=&flag&&wizz=fuzz": true,
      "foo://bar?wizz=fuzz&empty=&lang=en&flag&&q=test": true,
      "?q=test&lang=en&empty=&flag": true,
      "?lang=en&flag&empty=&q=test": true,
    ]
    
    for (url, result) in urls {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif

      XCTAssert(matcher(req) == result, "containsQueryParams(\"\(params)\") matcher failed when testing url \(url)")
    }
  }
    
  func testHasHeaderNamedIsTrue() {
#if swift(>=3.0)
    var req = URLRequest(url: URL(string: "foo://bar")!)
#else
    let req = NSMutableURLRequest(URL: NSURL(string: "foo://bar")!)
#endif
    req.addValue("1234567890", forHTTPHeaderField: "ArbitraryKey")

    let hasHeader = hasHeaderNamed("ArbitraryKey")(req)

    XCTAssertTrue(hasHeader)
  }
  
  func testHasHeaderNamedIsFalse() {
#if swift(>=3.0)
    let req = URLRequest(url: URL(string: "foo://bar")!)
#else
    let req = NSURLRequest(URL: NSURL(string: "foo://bar")!)
#endif

    let hasHeader = hasHeaderNamed("ArbitraryKey")(req)

    XCTAssertFalse(hasHeader)
  }
  
  func testHeaderValueForKeyEqualsIsTrue() {
#if swift(>=3.0)
    var req = URLRequest(url: URL(string: "foo://bar")!)
#else
    let req = NSMutableURLRequest(URL: NSURL(string: "foo://bar")!)
#endif
    req.addValue("bar", forHTTPHeaderField: "foo")
    
    let matchesHeader = hasHeaderNamed("foo", value: "bar")(req)
    
    XCTAssertTrue(matchesHeader)
  }
  
  func testHeaderValueForKeyEqualsIsFalse() {
#if swift(>=3.0)
    var req = URLRequest(url: URL(string: "foo://bar")!)
#else
    let req = NSMutableURLRequest(URL: NSURL(string: "foo://bar")!)
#endif
    req.addValue("bar", forHTTPHeaderField: "foo")
    
    let matchesHeader = hasHeaderNamed("foo", value: "baz")(req)
    
    XCTAssertFalse(matchesHeader)
  }
  
  func testHeaderValueForKeyEqualsDoesNotExist() {
#if swift(>=3.0)
    let req = URLRequest(url: URL(string: "foo://bar")!)
#else
    let req = NSURLRequest(URL: NSURL(string: "foo://bar")!)
#endif

    let matchesHeader = hasHeaderNamed("foo", value: "baz")(req)
    
    XCTAssertFalse(matchesHeader)
  }
  
  let sampleURLs = [
    // Absolute URLs
    "scheme:",
    "scheme://",
    "scheme://foo/bar/baz",
    "scheme://host/foo/bar",
    "scheme://host/foo/bar/baz",
    "scheme://host/foo/bar/baz?q=1",
    "scheme://host/foo/bar/baz#anchor",
    "scheme://host/foo/bar/baz;param",
    "scheme://host/foo/bar/baz/wizz",
    "scheme://host/path#/foo/bar/baz",
    "scheme://host/path?/foo/bar/baz",
    "scheme://host/path;/foo/bar/baz",
    // Relative URLs
    "foo/bar/baz",
    "foo/bar/baz?q=1",
    "foo/bar/baz#anchor",
    "foo/bar/baz;param",
    "foo/bar/baz/wizz",
    "path#/foo/bar/baz",
    "path?/foo/bar/baz",
    "path;/foo/bar/baz"
  ]
  
  let trueMatcher: OHHTTPStubsTestBlock = { _ in return true }
  let falseMatcher: OHHTTPStubsTestBlock = { _ in return false }
  
  func testOrOperator() {
    for url in sampleURLs {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif
      XCTAssert((trueMatcher || trueMatcher)(req) == true, "trueMatcher || trueMatcher should result in a trueMatcher")
      XCTAssert((trueMatcher || falseMatcher)(req) == true, "trueMatcher || falseMatcher should result in a trueMatcher")
      XCTAssert((falseMatcher || trueMatcher)(req) == true, "falseMatcher || trueMatcher should result in a trueMatcher")
      XCTAssert((falseMatcher || falseMatcher)(req) == false, "falseMatcher || falseMatcher should result in a falseMatcher")
    }
  }
  
  func testAndOperator() {
    for url in sampleURLs {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif
      XCTAssert((trueMatcher && trueMatcher)(req) == true, "trueMatcher && trueMatcher should result in a trueMatcher")
      XCTAssert((trueMatcher && falseMatcher)(req) == false, "trueMatcher && falseMatcher should result in a falseMatcher")
      XCTAssert((falseMatcher && trueMatcher)(req) == false, "falseMatcher && trueMatcher should result in a falseMatcher")
      XCTAssert((falseMatcher && falseMatcher)(req) == false, "falseMatcher && falseMatcher should result in a falseMatcher")
    }
  }
  
  func testNotOperator() {
    for url in sampleURLs {
#if swift(>=3.0)
      let req = URLRequest(url: URL(string: url)!)
#else
      let req = NSURLRequest(URL: NSURL(string: url)!)
#endif
      XCTAssert((!trueMatcher)(req) == false, "!trueMatcher should result in a falseMatcher")
      XCTAssert((!falseMatcher)(req) == true, "!falseMatcher should result in a trueMatcher")
    }
  }

#if swift(>=3.0)
#if OHHTTPSTUBS_NSURLSESSION_HTTPBODY
    func test_ohhttpStubs_httpBody() {
      var req = URLRequest(url: URL(string: "foo://bar")!)
      req.httpBody = Data()

      XCTAssert(req.ohhttpStubs_httpBody == req.httpBody)
    }
#endif
#endif
}
