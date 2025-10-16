//
//  JSONNormalizeTests.swift
//  MAGE
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class JSONNormalizeTests: XCTestCase {
    func testDropsNullsInObjectsKeepsInArrays() {
        let data = #"{"a":1,"b":null,"c":[1,null,2]}"#.data(using: .utf8)!
        let s = JSONNormalize.canonicalizeString(data)
        // Expect b removed; null stays inside the array
        XCTAssertEqual(s, #"{"a":1,"c":[1,null,2]}"#)
    }
}
