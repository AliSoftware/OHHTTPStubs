/***********************************************************************************
*
* Copyright (c) 2012 Olivier Halligon
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
***********************************************************************************/

/**
 * Swift Helpers
 */


#if swift(>=3.0)
#else
#if swift(>=2.2)
    extension OHHTTPStubs {
        private class func stubRequests(passingTest passingTest: OHHTTPStubsTestBlock, withStubResponse: OHHTTPStubsResponseBlock) -> OHHTTPStubsDescriptor {
            return stubRequestsPassingTest(passingTest, withStubResponse: withStubResponse)
        }
    }

    extension NSURLRequest {
        var httpMethod: String? { return HTTPMethod }
        var url: NSURL? { return URL }
    }

    extension NSURLComponents {
        private convenience init?(url: NSURL, resolvingAgainstBaseURL: Bool) {
            self.init(URL: url, resolvingAgainstBaseURL: resolvingAgainstBaseURL)
        }
    }

    private typealias URLRequest = NSURLRequest

    extension URLRequest {
        private func value(forHTTPHeaderField key: String) -> String? {
            return valueForHTTPHeaderField(key)
        }
    }
#endif
#endif


// MARK: Syntaxic Sugar for OHHTTPStubs

/**
 * Helper to return a `OHHTTPStubsResponse` given a fixture path, status code and optional headers.
 *
 * - Parameter filePath: the path of the file fixture to use for the response
 * - Parameter status: the status code to use for the response
 * - Parameter headers: the HTTP headers to use for the response
 *
 * - Returns: The `OHHTTPStubsResponse` instance that will stub with the given status code
 *            & headers, and use the file content as the response body.
 */
#if swift(>=3.0)
public func fixture(filePath: String, status: Int32 = 200, headers: [AnyHashable: Any]?) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(fileAtPath: filePath, statusCode: status, headers: headers)
}
#else
public func fixture(filePath: String, status: Int32 = 200, headers: [NSObject: AnyObject]?) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(fileAtPath: filePath, statusCode: status, headers: headers)
}
#endif

/**
 * Helper to call the stubbing function in a more concise way?
 *
 * - Parameter condition: the matcher block that determine if the request will be stubbed
 * - Parameter response: the stub reponse to use if the request is stubbed
 *
 * - Returns: The opaque `OHHTTPStubsDescriptor` that uniquely identifies the stub
 *            and can be later used to remove it with `removeStub:`
 */
#if swift(>=3.0)
@discardableResult
public func stub(condition: @escaping OHHTTPStubsTestBlock, response: @escaping OHHTTPStubsResponseBlock) -> OHHTTPStubsDescriptor {
    return OHHTTPStubs.stubRequests(passingTest: condition, withStubResponse: response)
}
#else
public func stub(condition: OHHTTPStubsTestBlock, response: OHHTTPStubsResponseBlock) -> OHHTTPStubsDescriptor {
    return OHHTTPStubs.stubRequests(passingTest: condition, withStubResponse: response)
}
#endif



// MARK: Create OHHTTPStubsTestBlock matchers

/**
 * Matcher testing that the `NSURLRequest` is using the **GET** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the GET method
 */
public func isMethodGET() -> OHHTTPStubsTestBlock {
  return { $0.httpMethod == "GET" }
}

/**
 * Matcher testing that the `NSURLRequest` is using the **POST** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the POST method
 */
public func isMethodPOST() -> OHHTTPStubsTestBlock {
  return { $0.httpMethod == "POST" }
}

/**
 * Matcher testing that the `NSURLRequest` is using the **PUT** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the PUT method
 */
public func isMethodPUT() -> OHHTTPStubsTestBlock {
  return { $0.httpMethod == "PUT" }
}

/**
 * Matcher testing that the `NSURLRequest` is using the **PATCH** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the PATCH method
 */
public func isMethodPATCH() -> OHHTTPStubsTestBlock {
    return { $0.httpMethod == "PATCH" }
}

/**
 * Matcher testing that the `NSURLRequest` is using the **DELETE** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the DELETE method
 */
public func isMethodDELETE() -> OHHTTPStubsTestBlock {
  return { $0.httpMethod == "DELETE" }
}

/**
 * Matcher for testing an `NSURLRequest`'s **scheme**.
 *
 * - Parameter scheme: The scheme to match
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            has the given scheme
 */
public func isScheme(_ scheme: String) -> OHHTTPStubsTestBlock {
    return { req in req.url?.scheme == scheme }
}

/**
 * Matcher for testing an `NSURLRequest`'s **host**.
 *
 * - Parameter host: The host to match
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            has the given host
 */
public func isHost(_ host: String) -> OHHTTPStubsTestBlock {
    return { req in req.url?.host == host }
}

/**
 * Matcher for testing an `NSURLRequest`'s **path**.
 *
 * - Parameter path: The path to match
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            has exactly the given path
 *
 * - Note: URL paths are usually absolute and thus starts with a '/' (which you
 *         should include in the `path` parameter unless you're testing relative URLs)
 */
public func isPath(_ path: String) -> OHHTTPStubsTestBlock {
    return { req in (req.url as NSURL?)?.path == path } // Need to cast to NSURL because URL.path does not behave like NSURL.path in Swift 3.0. URL.path does not stop at the first ';' and returns the entire string.
}

/**
 * Matcher for testing the start of an `NSURLRequest`'s **path**.
 *
 * - Parameter path: The path to match
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            starts with the given path
 *
 * - Note: URL paths are usually absolute and thus starts with a '/' (which you
 *         should include in the `path` parameter unless you're testing relative URLs)
 */
public func pathStartsWith(_ path: String) -> OHHTTPStubsTestBlock {
#if swift(>=3.0)
    return { req in req.url?.path.hasPrefix(path) ?? false }
#else
    return { req in req.url?.path?.hasPrefix(path) ?? false }
#endif
}

/**
 * Matcher for testing an `NSURLRequest`'s **path extension**.
 *
 * - Parameter ext: The file extension to match (without the dot)
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request path
 *            ends with the given extension
 */
public func isExtension(_ ext: String) -> OHHTTPStubsTestBlock {
    return { req in req.url?.pathExtension == ext }
}

/**
 * Matcher for testing an `NSURLRequest`'s **query parameters**.
 *
 * - Parameter params: The dictionary of query parameters to check the presence for
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds if the request contains
 *            the given query parameters with the given value.
 *
 * - Note: There is a difference between:
 *          (1) using `[q:""]`, which matches a query parameter "?q=" with an empty value, and
 *          (2) using `[q:nil]`, which matches a query parameter "?q" without a value at all
 */
@available(iOS 8.0, OSX 10.10, *)
public func containsQueryParams(_ params: [String:String?]) -> OHHTTPStubsTestBlock {
    return { req in
        if let url = req.url {
            let comps = NSURLComponents(url: url, resolvingAgainstBaseURL: true)
            if let queryItems = comps?.queryItems {
                for (k,v) in params {
                    if queryItems.filter({ qi in qi.name == k && qi.value == v }).count == 0 { return false }
                }
                return true
            }
        }
        return false
    }
}

/**
 * Matcher testing that the `NSURLRequest` headers contain a specific key
 * - Parameter name: the name of the key to search for in the `NSURLRequest`'s **allHTTPHeaderFields** property
 *  
 * - Returns: a matcher that returns true if the `NSURLRequest`'s headers contain a value for the key name
 */
public func hasHeaderNamed(_ name: String) -> OHHTTPStubsTestBlock {
    return { (req: URLRequest) -> Bool in
        return req.value(forHTTPHeaderField: name) != nil
    }
}

/**
 * Matcher testing that the `NSURLRequest` headers contain a specific key and the key's value is equal to the parameter value
 * - Parameter name: the name of the key to search for in the `NSURLRequest`'s **allHTTPHeaderFields** property
 * - Parameter value: the value to compare against the header's value
 *  
 * - Returns: a matcher that returns true if the `NSURLRequest`'s headers contain a value for the key name and it's value
 *            is equal to the parameter value
 */
public func hasHeaderNamed(_ name: String, value: String) -> OHHTTPStubsTestBlock {
    return { (req: URLRequest) -> Bool in
        return req.value(forHTTPHeaderField: name) == value
    }
}

// MARK: Operators on OHHTTPStubsTestBlock

/**
 * Combine different `OHHTTPStubsTestBlock` matchers with an 'OR' operation.
 *
 * - Parameter lhs: the first matcher to test
 * - Parameter rhs: the second matcher to test
 *
 * - Returns: a matcher (`OHHTTPStubsTestBlock`) that succeeds if either of the given matchers succeeds
 */
#if swift(>=3.0)
public func || (lhs: @escaping OHHTTPStubsTestBlock, rhs: @escaping OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in lhs(req) || rhs(req) }
}
#else
public func || (lhs: OHHTTPStubsTestBlock, rhs: OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in lhs(req) || rhs(req) }
}
#endif

/**
 * Combine different `OHHTTPStubsTestBlock` matchers with an 'AND' operation.
 *
 * - Parameter lhs: the first matcher to test
 * - Parameter rhs: the second matcher to test
 *
 * - Returns: a matcher (`OHHTTPStubsTestBlock`) that only succeeds if both of the given matchers succeeds
 */
#if swift(>=3.0)
public func && (lhs: @escaping OHHTTPStubsTestBlock, rhs: @escaping OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in lhs(req) && rhs(req) }
}
#else
public func && (lhs: OHHTTPStubsTestBlock, rhs: OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in lhs(req) && rhs(req) }
}
#endif

/**
 * Create the opposite of a given `OHHTTPStubsTestBlock` matcher.
 *
 * - Parameter expr: the matcher to negate
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that only succeeds if the expr matcher fails
 */
#if swift(>=3.0)
public prefix func ! (expr: @escaping OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in !expr(req) }
}
#else
public prefix func ! (expr: OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in !expr(req) }
}
#endif
