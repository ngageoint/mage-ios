//
//  ErrorMappingTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class ErrorMappingTests: XCTestCase {
    func test401BecomesInvalidCredentials() {
        let err = AuthErrorMapping.map(.init(status: 401, data: #"{"error":"Unauthorized"}"#.data(using: .utf8)))
        XCTAssertEqual(err, .invalidCredentials)
    }
    
    func test409PolicyViolationWithMessage() {
        let err = AuthErrorMapping.map(.init(status: 409, data: #"{"error":"Username is not available"}"#.data(using: .utf8)))
        XCTAssertEqual(err, .policyViolation(message: "Username is not available"))
    }
}
