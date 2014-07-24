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


/*----------------------------------------------------------------------------------
 * NOTE
 *
 * This file mirror the new XCTestExpectation API from Xcode 6's XCTest framework
 * (at least part of it) so that we can use the same API in older Xcode versions
 ----------------------------------------------------------------------------------*/


#if __IPHONE_OS_VERSION_MAX_ALLOWED < 80000

#import "XCTestExpectation+OHRetroCompat.h"
#import <Foundation/Foundation.h>

#import <objc/runtime.h>

static void* kExpectationsAssocKey = &kExpectationsAssocKey;
static NSTimeInterval const kRunLoopSamplingInterval = 0.01;


/////////////////////////////////////////////////////////

@interface XCTestExpectation()
@property(strong) NSString* descritionString;
@property(weak) XCTestCase* associatedTestCase;
@end

/////////////////////////////////////////////////////////

@implementation XCTestCase(NFAsync)

- (void)lockExpectationsArrayAndDo:(void(^)(NSMutableArray* expectations))block
{
    @synchronized(self)
    {
        NSMutableArray* expectations = objc_getAssociatedObject(self, kExpectationsAssocKey);
        if (!expectations)
        {
            expectations = [NSMutableArray new];
            objc_setAssociatedObject(self, kExpectationsAssocKey, expectations, OBJC_ASSOCIATION_RETAIN);
        }
        block(expectations);
    }
}



- (XCTestExpectation *)expectationWithDescription:(NSString *)description
{
    XCTestExpectation* expectation = [XCTestExpectation new];
    expectation.associatedTestCase = self;
    expectation.descritionString = description;

    [self lockExpectationsArrayAndDo:^(NSMutableArray *expectations) {
        [expectations addObject:expectation];
    }];
    
    return expectation;
}

- (void)waitForExpectationsWithTimeout:(NSTimeInterval)timeout handler:(XCWaitCompletionHandler)handlerOrNil
{
    NSDate* timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    __block BOOL allExpectationsFulfilled = NO;
    
    while ([timeoutDate timeIntervalSinceNow]>0)
    {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, kRunLoopSamplingInterval, YES);

        [self lockExpectationsArrayAndDo:^(NSMutableArray *expectations) {
            allExpectationsFulfilled = (expectations.count == 0);
        }];
        if (allExpectationsFulfilled) break;
    }
    
    __block NSError* error = nil;
    __block NSString* expectationsList = nil;
    
    [self lockExpectationsArrayAndDo:^(NSMutableArray *expectations) {
        if (expectations.count > 0)
        {
            expectationsList = [expectations componentsJoinedByString:@", "];
            error = [NSError errorWithDomain:@"com.apple.XCTestErrorDomain" code:0 userInfo:nil];
            [expectations removeAllObjects];
        }
    }];
    
    if (handlerOrNil)
    {
        handlerOrNil(error);
    }
    
    if (error)
    {
        XCTFail(@"Asynchronous wait failed: Exceeded timeout of %0.f seconds, with unfulfilled expectations: %@.",
                timeout, expectationsList);
    }
}

@end

/////////////////////////////////////////////////////////

@implementation XCTestExpectation
- (void)fulfill
{
    NSAssert(_associatedTestCase, @"The test case associated with this XCTestExpectation %@ has already finished!", self);
    
    [_associatedTestCase lockExpectationsArrayAndDo:^(NSMutableArray *expectations) {
        NSAssert([expectations containsObject:self], @"The XCTestExpectation %@ has already been fulfilled!", self);
        [expectations removeObject:self];
    }];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"\"%@\"", _descritionString];
}
@end

#endif

