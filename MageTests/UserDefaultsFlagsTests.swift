//
//  UserDefaultsFlagsTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class UserDefaultsFlagsTests: XCTestCase {
    
    func testAuthNextGenEnabled_DefaultsFalseAndFlips() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "authNextGenEnabled")
        XCTAssertFalse(defaults.authNextGenEnabled)
        defaults.authNextGenEnabled = true
        XCTAssertTrue(defaults.authNextGenEnabled)
        defaults.authNextGenEnabled = false
        XCTAssertFalse(defaults.authNextGenEnabled)
    }

}
