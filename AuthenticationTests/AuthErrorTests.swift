//
//  AuthErrorTests.swift
//  AuthenticationTests
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class AuthErrorTests: XCTestCase {
    func testLocalizedDescriptionsAreNonEmpty() {
        let cases: [AuthError] = [
            .invalidCredentials, .accountDisabled, .network(underlying: nil),
            .server(status: 500, message: nil), .decoding(underlying: nil),
            .policyViolation(message: "Too short"), .cancelled, .unimplemented()
            ]
        
        for err in cases { XCTAssertFalse((err.errorDescription ?? "").isEmpty) }
    }
    
    func testEquatable() {
        XCTAssertEqual(AuthError.invalidCredentials, .invalidCredentials)
        XCTAssertNotEqual(AuthError.invalidCredentials, .accountDisabled)
    }
}
