#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "OHPathHelpers.h"

@interface OHPathHelpersTests : XCTestCase

@end

@implementation OHPathHelpersTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testOHResourceBundle {
    NSBundle *classBundle = [NSBundle bundleForClass:self.class];
    NSBundle *expectedBundle = [NSBundle bundleWithPath:[classBundle pathForResource:@"empty"
                                                                              ofType:@"bundle"]];
    
    XCTAssertEqual(OHResourceBundle(@"empty", self.class), expectedBundle);
}

@end
