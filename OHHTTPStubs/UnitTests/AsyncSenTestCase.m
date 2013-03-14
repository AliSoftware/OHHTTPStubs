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


#import "AsyncSenTestCase.h"

@interface AsyncSenTestCase()
@property(atomic, assign) NSUInteger asyncTestCaseSignaledCount;
@end

static const NSTimeInterval kRunLoopSamplingInterval = 0.01;



@implementation AsyncSenTestCase

@synthesize asyncTestCaseSignaledCount = _asyncTestCaseSignaledCount;

-(void)waitForAsyncOperationWithTimeout:(NSTimeInterval)timeout
{
    [self waitForAsyncOperations:1 withTimeout:timeout];
}

-(void)waitForAsyncOperations:(NSUInteger)count withTimeout:(NSTimeInterval)timeout
{
    NSDate* timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while ((self.asyncTestCaseSignaledCount < count) && ([timeoutDate timeIntervalSinceNow]>0))
    {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, kRunLoopSamplingInterval, YES);
    }
    
    // Reset the counter for next time, in case we call this method again later
    // (don't reset it at the beginning of the method because we should be able to call
    // notifyAsyncOperationDone *before* this method if we wanted to)
    self.asyncTestCaseSignaledCount = 0;
    
    if ([timeoutDate timeIntervalSinceNow]<0)
    {
        // now is after timeoutDate, we timed out
        STFail(@"Timed out while waiting for Async Operations to finish.");
    }
}

-(void)waitForTimeout:(NSTimeInterval)timeout
{
    NSDate* waitEndDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while ([waitEndDate timeIntervalSinceNow]>0)
    {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, kRunLoopSamplingInterval, YES);
    }
}

-(void)notifyAsyncOperationDone
{
    @synchronized(self)
    {
        self.asyncTestCaseSignaledCount = self.asyncTestCaseSignaledCount+1;
    }
}

@end
