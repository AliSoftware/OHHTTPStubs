//
//  SwiftHelpersTests.swift
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 20/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation
import XCTest
import OHHTTPStubs

class SwiftHelpersTests : XCTestCase {
    
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
            let req = NSURLRequest(URL: NSURL(string: url)!)
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
            let req = NSURLRequest(URL: NSURL(string: url)!)
            XCTAssert(matcher(req) == result, "isHost(\"foo\") matcher failed when testing url \(url)")
        }
    }
    
    func testIsPath_absoluteURL() {
        testIsPath("/foo/bar/baz", isAbsoluteMatcher: true)
    }
    
    func testIsPath_relativeURL() {
        testIsPath("foo/bar/baz", isAbsoluteMatcher: false)
    }
    
    func testIsPath(path: String, isAbsoluteMatcher: Bool) {
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
            let req = NSURLRequest(URL: NSURL(string: url)!)
            let p = req.URL?.path
            print("URL: \(url) -> Path: \(p)")
            XCTAssert(matcher(req) == result, "isPath(\"\(path)\" matcher failed when testing url \(url)")
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
            let req = NSURLRequest(URL: NSURL(string: url)!)
            XCTAssert(matcher(req) == result, "isExtension(\"txt\") matcher failed when testing url \(url)")
        }

    }
    
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
            let req = NSURLRequest(URL: NSURL(string: url)!)
            XCTAssert(matcher(req) == result, "containsQueryParams(\"\(params)\") matcher failed when testing url \(url)")
        }
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
            let req = NSURLRequest(URL: NSURL(string: url)!)
            XCTAssert((trueMatcher || trueMatcher)(req) == true, "trueMatcher || trueMatcher should result in a trueMatcher")
            XCTAssert((trueMatcher || falseMatcher)(req) == true, "trueMatcher || falseMatcher should result in a trueMatcher")
            XCTAssert((falseMatcher || trueMatcher)(req) == true, "falseMatcher || trueMatcher should result in a trueMatcher")
            XCTAssert((falseMatcher || falseMatcher)(req) == false, "falseMatcher || falseMatcher should result in a falseMatcher")
        }
    }
    
    func testAndOperator() {
        for url in sampleURLs {
            let req = NSURLRequest(URL: NSURL(string: url)!)
            XCTAssert((trueMatcher && trueMatcher)(req) == true, "trueMatcher && trueMatcher should result in a trueMatcher")
            XCTAssert((trueMatcher && falseMatcher)(req) == false, "trueMatcher && falseMatcher should result in a falseMatcher")
            XCTAssert((falseMatcher && trueMatcher)(req) == false, "falseMatcher && trueMatcher should result in a falseMatcher")
            XCTAssert((falseMatcher && falseMatcher)(req) == false, "falseMatcher && falseMatcher should result in a falseMatcher")
        }
    }
    
    func testNotOperator() {
        for url in sampleURLs {
            let req = NSURLRequest(URL: NSURL(string: url)!)
            XCTAssert((!trueMatcher)(req) == false, "!trueMatcher should result in a falseMatcher")
            XCTAssert((!falseMatcher)(req) == true, "!falseMatcher should result in a trueMatcher")
        }
    }
}
