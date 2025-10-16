//
//  ContractAssert.swift
//  MAGE
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest

func AssertEqualContract(_ lhs: HTTPResponse, _ rhs: HTTPResponse,
                         file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(lhs.status, rhs.status, file: file, line: line)
    let l = JSONNormalize.canonicalizeString(lhs.body)
    let r = JSONNormalize.canonicalizeString(rhs.body)
    XCTAssertEqual(l, r, file: file, line: line)
}
