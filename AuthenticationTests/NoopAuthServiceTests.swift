//
//  NoopAuthServiceTests.swift
//  AuthenticationTests
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class NoopAuthServiceTests: XCTestCase {
    
    func testNoopAlwaysUnimplemented() async {
        let svc = NoopAuthService()
        
        await XCTAssertThrowsErrorAsync(try await svc.loginLocal(.init(username: "u", password: "p")))
        await XCTAssertThrowsErrorAsync(try await svc.beginIDP(.oidc))
        await XCTAssertThrowsErrorAsync(try await svc.completeIDP())
        await XCTAssertThrowsErrorAsync(try await svc.fetchCaptcha(for: "u"))
        await XCTAssertThrowsErrorAsync(try await svc.verifyCaptcha(token: "t", value: "v"))
        await XCTAssertThrowsErrorAsync(try await svc.signup(.init(displayName: "d", username: "u", password: "p", email: nil)))
    }
}

// Small async helper so we don't pull in extra deps
private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error", file: file, line: line)
        } catch {
            /* expected */
        }
    }
}
