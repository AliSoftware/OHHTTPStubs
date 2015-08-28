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

import OHHTTPStubs

/**
 * Matcher for a request Scheme
 *
 * @param scheme The scheme to match
 *
 * @returns a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *          has the given scheme
 */
public func isScheme(scheme: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.scheme == scheme }
}

/**
 * Matcher for a request Host
 *
 * @param host The host to match
 *
 * @returns a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *          has the given host
 */
public func isHost(host: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.host == host }
}

/**
 * Matcher for a request Path
 *
 * @param path The path to match
 *
 * @returns a matcher (OHHTTPStubsTestBlock) that succeeds only if the request
 *          has exactly the given path
 */
public func isPath(path: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.path == path }
}

/**
 * Matcher for a request path extension
 *
 * @param ext The file extension to match (without the dot)
 *
 * @returns a matcher (OHHTTPStubsTestBlock) that succeeds only if the request path
 *          ends with the given extension
 */
public func isExtension(ext: String) -> OHHTTPStubsTestBlock {
    return { req in req.URL?.pathExtension == ext }
}

/**
 * Matcher for a request query parameters
 *
 * @param params The dictionary of query parameters to check the presence for
 *
 * @returns a matcher (OHHTTPStubsTestBlock) that succeeds if the request contains
 *          the given query parameters with the given value.
 */
public func hasQueryParams(params: [String:String?]) -> OHHTTPStubsTestBlock {
    return { req in
        if let url = req.URL {
            let comps = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
            if let queryItems = comps?.queryItems {
                for (k,v) in params {
                    if queryItems.filter({ qi in qi.name == k && qi.value == v }).count == 0 { return false }
                }
            }
        }
        return false
    }
}

/**
 * Combine different matchers with an 'OR' operation
 *
 * @param lhs the first matcher to test
 *
 * @param rhs the second matcher to test
 *
 * @returns a matcher (OHHTTPStubsTestBlock) that succeeds if either of the given matchers succeeds
 */
public func || (lhs: OHHTTPStubsTestBlock, rhs: OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in lhs(req) || rhs(req) }
}

/**
 * Combine different matchers with an 'AND' operation
 *
 * @param lhs the first matcher to test
 *
 * @param rhs the second matcher to test
 *
 * @returns a matcher (OHHTTPStubsTestBlock) that only succeeds if both of the given matchers succeeds
 */
public func &&(lhs: OHHTTPStubsTestBlock, rhs: OHHTTPStubsTestBlock) -> OHHTTPStubsTestBlock {
    return { req in lhs(req) && rhs(req) }
}

/**
 * Helper to return a response given a fixture path and status code
 *
 * @param filePath the path of the file fixture to use for the response
 *
 * @param status the status code to use for the response
 *
 * @param headers the HTTP headers to use for the response
 */
public func fixture(filePath: String, status: Int32 = 200, #headers: [NSObject: AnyObject]?) -> OHHTTPStubsResponse {
    return OHHTTPStubsResponse(fileAtPath: filePath, statusCode: status, headers: headers)
}

/**
 * Helper to call the stubbing function in a more concise way
 *
 * @param condition the matcher block that determine if the request will be stubbed
 *
 * @param response the stub reponse to use if the request is stubbed
 */
public func stub(condition: OHHTTPStubsTestBlock, response: OHHTTPStubsResponseBlock) -> OHHTTPStubsDescriptor {
    return OHHTTPStubs.stubRequestsPassingTest(condition, withStubResponse: response)
}
