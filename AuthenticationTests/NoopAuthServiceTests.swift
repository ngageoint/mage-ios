//
//  NoopAuthServiceTests.swift
//  AuthenticationTests
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import Authentication

final class NoopAuthServiceTests: XCTestCase {

    func testNoopAlwaysUnimplemented() async {
        let svc = NoopAuthService()
//        await XCTAssertThrowsErrorAsync
    }

}


private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T,
                                      file: StaticString = #filePath, line: UInt = #line) async {
        do { _ = try await expression(); XCTFail("Expected error", file: file, line: line) }
        catch { /* expected */ }
    }
}
