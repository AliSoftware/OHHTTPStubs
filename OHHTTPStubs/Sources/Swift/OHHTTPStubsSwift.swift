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
public func fixture(filePath: String, status: Int32 = 200, headers: [NSObject: AnyObject]?) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(fileAtPath: filePath, statusCode: status, headers: headers)
}

/**
 * Helper to call the stubbing function in a more concise way?
 *
 * - Parameter condition: the matcher block that determine if the request will be stubbed
 * - Parameter response: the stub reponse to use if the request is stubbed
 *
 * - Returns: The opaque `OHHTTPStubsDescriptor` that uniquely identifies the stub
 *            and can be later used to remove it with `removeStub:`
 */
public func stub(condition: OHHTTPStubsTestBlock, response: OHHTTPStubsResponseBlock) -> OHHTTPStubsDescriptor {
    return OHHTTPStubs.stubRequestsPassingTest(condition, withStubResponse: response)
}



// MARK: Create OHHTTPStubsTestBlock matchers

/**
 * Matcher testing that the `NSURLRequest` is using the **GET** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the GET method
 */
public func isMethodGET() -> OHHTTPStubsTestBlock {
  return { $0.HTTPMethod == "GET" }
}

/**
 * Matcher testing that the `NSURLRequest` is using the **POST** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the POST method
 */
public func isMethodPOST() -> OHHTTPStubsTestBlock {
  return { $0.HTTPMethod == "POST" }
}

/**
 * Matcher testing that the `NSURLRequest` is using the **PUT** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the PUT method
 */
public func isMethodPUT() -> OHHTTPStubsTestBlock {
  return { $0.HTTPMethod == "PUT" }
}

/**
 * Matcher testing that the `NSURLRequest` is using the **PATCH** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the PATCH method
 */
public func isMethodPATCH() -> OHHTTPStubsTestBlock {
    return { $0.HTTPMethod == "PATCH" }
}

/**
 * Matcher testing that the `NSURLRequest` is using the **DELETE** `HTTPMethod`
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            is using the DELETE method
 */
public func isMethodDELETE() -> OHHTTPStubsTestBlock {
  return { $0.HTTPMethod == "DELETE" }
}

/**
 * Matcher for testing an `NSURLRequest`'s **scheme**.
 *
 * - Parameter scheme: The scheme to match
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            has the given scheme
 */
public func isScheme(scheme: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.scheme == scheme }
}

/**
 * Matcher for testing an `NSURLRequest`'s **host**.
 *
 * - Parameter host: The host to match
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *            has the given host
 */
public func isHost(host: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.host == host }
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
public func isPath(path: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.path == path }
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
public func pathStartsWith(path: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.path?.hasPrefix(path) ?? false }
}

/**
 * Matcher for testing an `NSURLRequest`'s **path extension**.
 *
 * - Parameter ext: The file extension to match (without the dot)
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that succeeds only if the request path
 *            ends with the given extension
 */
public func isExtension(ext: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.pathExtension == ext }
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
public func containsQueryParams(params: [String:String?]) -> OHHTTPStubsTestBlock {
    return { req in
        if let url = req.URL {
            let comps = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
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
public func hasHeaderNamed(name: String) -> OHHTTPStubsTestBlock {
    return { (req: NSURLRequest) -> Bool in
        return req.valueForHTTPHeaderField(name) != nil
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
public func hasHeaderNamed(name: String, value: String) -> OHHTTPStubsTestBlock {
    return { (req: NSURLRequest) -> Bool in
        return req.valueForHTTPHeaderField(name) == value
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
public func || (lhs: OHHTTPStubsTestBlock, rhs: OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in lhs(req) || rhs(req) }
}

/**
 * Combine different `OHHTTPStubsTestBlock` matchers with an 'AND' operation.
 *
 * - Parameter lhs: the first matcher to test
 * - Parameter rhs: the second matcher to test
 *
 * - Returns: a matcher (`OHHTTPStubsTestBlock`) that only succeeds if both of the given matchers succeeds
 */
public func && (lhs: OHHTTPStubsTestBlock, rhs: OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in lhs(req) && rhs(req) }
}

/**
 * Create the opposite of a given `OHHTTPStubsTestBlock` matcher.
 *
 * - Parameter expr: the matcher to negate
 *
 * - Returns: a matcher (OHHTTPStubsTestBlock) that only succeeds if the expr matcher fails
 */
public prefix func ! (expr: OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in !expr(req) }
}
