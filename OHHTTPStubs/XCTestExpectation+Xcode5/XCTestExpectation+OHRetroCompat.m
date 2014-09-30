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

#if XCODE_VERSION < 0600

#import "XCTestExpectation+OHRetroCompat.h"
#import <Foundation/Foundation.h>

#import <libkern/OSAtomic.h>

static NSTimeInterval const kRunLoopSamplingInterval = 0.01;


/////////////////////////////////////////////////////////

@interface XCTestExpectation()
@property(strong) NSString* descritionString;
@property(weak) XCTestCase* associatedTestCase;
@property(readonly) BOOL fulfilled;
#if XCTestExpectation_OHRetroCompat_BETTER_FAILURE_LOCATIONS
@property(assign) const char* sourceFile;
@property(assign) NSUInteger sourceLine;
#endif
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

#if XCTestExpectation_OHRetroCompat_BETTER_FAILURE_LOCATIONS
#undef expectationWithDescription
#undef waitForExpectationsWithTimeout
#endif

- (void)setUp
{
    [super setUp];
    
    _expectations = [NSMutableArray new];
    _unfulfilledExpectationsCount = 0;
}

- (void)tearDown
{
    [super tearDown];
    
    if (!OSAtomicCompareAndSwap32(0, 0, &_unfulfilledExpectationsCount)) // if unfulfilledExpectationsCount != 0
    {
        OSSpinLockLock(&_expectationsLock);
        [_expectations filterUsingPredicate:[NSPredicate predicateWithFormat:@"fulfilled == NO"]];
#if XCTestExpectation_OHRetroCompat_BETTER_FAILURE_LOCATIONS
        // Locate Xcode test failures at the exact line of each expectation, if we have thie FILE+LINE information
        for(XCTestExpectation* expectation in _expectations)
        {
            _XCTFailureHandler(self, YES, expectation.sourceFile, expectation.sourceLine, _XCTFailureDescription(_XCTAssertion_Fail, 0), @"Failed due to unwaited expectation.");
        }
#else
        XCTFail(@"Failed due to unwaited expectations: %@.", [_expectations componentsJoinedByString:@", "]);
#endif
        [_expectations removeAllObjects];
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

- (void)decrementUnfulfilledExpectationsCount
{
    OSAtomicDecrement32(&_unfulfilledExpectationsCount);
}

- (void)waitForExpectationsWithTimeout:(NSTimeInterval)timeout handler:(XCWaitCompletionHandler)handlerOrNil
{
    [self __file:NULL line:0 waitForExpectationsWithTimeout:timeout handler:handlerOrNil];
}

- (void)__file:(const char*)_caller_source_file line:(NSUInteger)_caller_source_line waitForExpectationsWithTimeout:(NSTimeInterval)timeout handler:(XCWaitCompletionHandler)handlerOrNil
{
    NSDate* timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    
    while ([timeoutDate timeIntervalSinceNow]>0)
    {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, kRunLoopSamplingInterval, YES);
        if (OSAtomicCompareAndSwap32(0, 0, &_unfulfilledExpectationsCount)) break; // if all expectations fulfilled, break
    }
    
    NSError* error = nil;
    
    if (!OSAtomicCompareAndSwap32(0, 0, &_unfulfilledExpectationsCount)) // if unfulfilledExpectationsCount != 0
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
        [_expectations filterUsingPredicate:[NSPredicate predicateWithFormat:@"fulfilled == NO"]];
        NSString* expectationsList = [_expectations componentsJoinedByString:@", "];
        [_expectations removeAllObjects];
        OSAtomicCompareAndSwap32(_unfulfilledExpectationsCount, 0, &_unfulfilledExpectationsCount); // reset to 0
        OSSpinLockUnlock(&_expectationsLock);
#if XCTestExpectation_OHRetroCompat_BETTER_FAILURE_LOCATIONS
        _XCTFailureHandler(self, YES, _caller_source_file, _caller_source_line, _XCTFailureDescription(_XCTAssertion_Fail, 0),
                           @"Asynchronous wait failed: Exceeded timeout of %g seconds, with unfulfilled expectations: %@.",
                           timeout, expectationsList);
#else
        XCTFail(@"Asynchronous wait failed: Exceeded timeout of %g seconds, with unfulfilled expectations: %@.",
                timeout, expectationsList);
        
#endif
    }
}

#if XCTestExpectation_OHRetroCompat_BETTER_FAILURE_LOCATIONS
- (XCTestExpectation *)__file:(const char*)_caller_source_file line:(NSUInteger)_caller_source_line
 expectationWithDescription:(NSString *)description
{
    XCTestExpectation* expectation = [self expectationWithDescription:description];
    expectation.sourceFile = _caller_source_file;
    expectation.sourceLine = _caller_source_line;
    return expectation;
}
#endif

@end

/////////////////////////////////////////////////////////

@implementation XCTestExpectation
- (void)fulfill
{
    if(!_associatedTestCase)
    {
        [NSException raise:NSInternalInconsistencyException format:@"The test case associated with this XCTestExpectation %@ has already finished!", self];
    }
    if (_fulfilled)
    {
        [NSException raise:NSInternalInconsistencyException format:@"The XCTestExpectation %@ has already been fulfilled!", self];
    }
    _fulfilled = YES;
    [_associatedTestCase decrementUnfulfilledExpectationsCount];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"\"%@\"", _descritionString];
}
@end

#endif

