#import <XCTest/XCTest.h>
#import "OHHTTPStubs.h"

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
