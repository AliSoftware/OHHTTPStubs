//
//  TestHelper.h
//  OHHTTPStubs
//
//  Created by Olivier Halligon on 24/10/2016.
//  Copyright © 2016 AliSoftware. All rights reserved.
//

#define XCTAssertInRange(expectation, rangeStart, rangeLength, message) \
  XCTAssertEqualWithAccuracy((expectation), (rangeStart)+(rangeLength)/2, (rangeLength)/2, message)
