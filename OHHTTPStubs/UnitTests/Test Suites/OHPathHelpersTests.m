#import <XCTest/XCTest.h>

#if OHHTTPSTUBS_USE_STATIC_LIBRARY
#import "OHHTTPStubs.h"
#import "OHPathHelpers.h"
#else
@import OHHTTPStubs;
#endif

@interface OHPathHelpersTests : XCTestCase
@end

@implementation OHPathHelpersTests

- (void)testOHResourceBundle {
    NSBundle *classBundle = [NSBundle bundleForClass:self.class];
    NSBundle *expectedBundle = [NSBundle bundleWithPath:[classBundle pathForResource:@"empty"
                                                                              ofType:@"bundle"]];
    
    XCTAssertEqual(OHResourceBundle(@"empty", self.class), expectedBundle);
}

@end
