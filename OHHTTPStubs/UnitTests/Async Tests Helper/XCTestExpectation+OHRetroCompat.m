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


#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 80000) \
 || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED)  && __MAC_OS_X_VERSION_MAX_ALLOWED < 101000)


#import "XCTestExpectation+OHRetroCompat.h"
#import <Foundation/Foundation.h>

#import <libkern/OSAtomic.h>

static NSTimeInterval const kRunLoopSamplingInterval = 0.01;


/////////////////////////////////////////////////////////

@interface XCTestExpectation()
@property(strong) NSString* descritionString;
@property(weak) XCTestCase* associatedTestCase;
@end

@interface XCTestCaseAsync()
{
    NSMutableArray* _expectations;
    OSSpinLock _expectationsLock;
    int32_t _unfulfilledExpectationsCount;
}
@end


/////////////////////////////////////////////////////////

@implementation XCTestCaseAsync

- (void)setUp
{
    [super setUp];
    _expectations = [NSMutableArray new];
    _unfulfilledExpectationsCount = 0;
}

- (void)tearDown
{
    [super tearDown];
    if (!OSAtomicCompareAndSwap32(0, 0, &_unfulfilledExpectationsCount))
    {
        OSSpinLockLock(&_expectationsLock);
        XCTFail(@"Failed due to unwaited expectations: %@.", [_expectations componentsJoinedByString:@", "]);
//        // Locate Xcode test failures at the exact line of each expectation, if we have thie FILE+LINE information
//        for(XCTestExpectation* expectation in _expectations)
//        {
//            _XCTFailureHandler(self, YES, expectation.file, expectation.line, _XCTFailureDescription(_XCTAssertion_Fail, 0), @"Failed due to unwaited expectations.");
//        }
        OSSpinLockUnlock(&_expectationsLock);
    }
}

- (XCTestExpectation *)expectationWithDescription:(NSString *)description
{
    XCTestExpectation* expectation = [XCTestExpectation new];
    expectation.associatedTestCase = self;
    expectation.descritionString = description;

    OSSpinLockLock(&_expectationsLock);
    {
        [_expectations addObject:expectation];
        OSAtomicIncrement32(&_unfulfilledExpectationsCount);
    }
    OSSpinLockUnlock(&_expectationsLock);
    
    return expectation;
}

- (void)fulfillExpectation:(XCTestExpectation*)expectation
{
    OSSpinLockLock(&_expectationsLock);
    if ([_expectations containsObject:self])
    {
        [NSException raise:NSInternalInconsistencyException format:@"The XCTestExpectation %@ has already been fulfilled!", expectation];
    }
    [_expectations removeObject:expectation];
    OSAtomicDecrement32(&_unfulfilledExpectationsCount);
    OSSpinLockUnlock(&_expectationsLock);
}

- (void)waitForExpectationsWithTimeout:(NSTimeInterval)timeout handler:(XCWaitCompletionHandler)handlerOrNil
{
    NSDate* timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    
    while ([timeoutDate timeIntervalSinceNow]>0)
    {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, kRunLoopSamplingInterval, YES);
        if (OSAtomicCompareAndSwap32(0, 0, &_unfulfilledExpectationsCount)) break;
    }
    
    NSError* error = nil;
    
    if (!OSAtomicCompareAndSwap32(0, 0, &_unfulfilledExpectationsCount))
    {
        error = [NSError errorWithDomain:@"com.apple.XCTestErrorDomain" code:0 userInfo:nil];
    }
    
    if (handlerOrNil)
    {
        handlerOrNil(error);
    }
    
    if (error)
    {
        OSSpinLockLock(&_expectationsLock);
        NSString* expectationsList = [_expectations componentsJoinedByString:@", "];
        [_expectations removeAllObjects];
        OSAtomicCompareAndSwap32(_unfulfilledExpectationsCount, 0, &_unfulfilledExpectationsCount);
        OSSpinLockUnlock(&_expectationsLock);
        
        XCTFail(@"Asynchronous wait failed: Exceeded timeout of %0.f seconds, with unfulfilled expectations: %@.",
                timeout, expectationsList);
//        _XCTFailureHandler(self, YES, file, line, _XCTFailureDescription(_XCTAssertion_Fail, 0),
//                           @"Asynchronous wait failed: Exceeded timeout of %0.f seconds, with unfulfilled expectations: %@.",
//                           timeout, expectationsList);
    }
}

@end

/////////////////////////////////////////////////////////

@implementation XCTestExpectation
- (void)fulfill
{
    if(!_associatedTestCase)
    {
        [NSException raise:NSInternalInconsistencyException format:@"The test case associated with this XCTestExpectation %@ has already finished!", self];
    }
    [_associatedTestCase fulfillExpectation:self];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"\"%@\"", _descritionString];
}
@end

#endif

