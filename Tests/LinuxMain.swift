import XCTest

import RateLimitMiddlewareTests

var tests = [XCTestCaseEntry]()
tests += RateLimitMiddlewareTests.allTests()
XCTMain(tests)
