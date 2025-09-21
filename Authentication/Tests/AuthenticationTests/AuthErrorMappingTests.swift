//
//  AuthErrorMappingTests.swift
//  AuthenticationTests
//
//  Created by Brent Michalski on 9/21/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import Authentication

final class AuthErrorMappingTests: XCTestCase {

    func testUnauthorizedUsersFallbackMessage() {
        let (status, msg) = AuthError.unauthorized.toAuthStatusAndMessage(fallbackInvalidCredsMessage: "Invalid credentials (custom).")
        XCTAssertEqual(status, .unableToAuthenticate)
        XCTAssertEqual(msg, "Invalid credentials (custom).")
    }

    func testInvalidCredentialsUsesFallbackMessage() {
        let (status, msg) = AuthError.invalidCredentials.toAuthStatusAndMessage(fallbackInvalidCredsMessage: "Invalid LDAP credentials.")
        XCTAssertEqual(status, .unableToAuthenticate)
        XCTAssertEqual(msg, "Invalid LDAP credentials.")
    }
    
    func testAccountDisabled() {
        let (status, msg) = AuthError.accountDisabled.toAuthStatusAndMessage()
        XCTAssertEqual(status, .unableToAuthenticate)
        XCTAssertEqual(msg, "Account disabled.")
    }
    
    func testRateLimitedWithRetryAfter() {
        let (status, msg) = AuthError.rateLimited(retryAfterSeconds: 90).toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Too many attempts. Try again in 90s.")
    }
    
    func testRateLimitedWithoutRetryAfter() {
        let (status, msg) = AuthError.rateLimited(retryAfterSeconds: nil).toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Too many attempts. Try again later.")
    }
    
    func testInvalidInputPropagatesServerMessage() {
        let (status, msg) = AuthError.invalidInput(message: "Email is required.").toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Email is required.")
    }
    
    func testServer500FallsBackToDefaultMessage() {
        let (status, msg) = AuthError.server(status: 500, message: nil).toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Server error (500).")
    }
    
    func testNetworkURLErrorNotConnected() {
        let urlErr = URLError(.notConnectedToInternet)
        let (status, msg) = AuthError.network(underlying: urlErr).toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "No internet connection.")
    }
    
    func testNetworkURLErrorTimeout() {
        let urlErr = URLError(.timedOut)
        let (status, msg) = AuthError.network(underlying: urlErr).toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Request timed out.")
    }
    
    func testNetworkGenericErrorFallsBackToLocalizedDescription() {
        struct DummyError: LocalizedError {
            let message: String
            var errorDescription: String? { message }
        }
        let dummy = DummyError(message: "Something odd happened.")
        let (status, msg) = AuthError.network(underlying: dummy).toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Something odd happened.")
    }
    
    func testMalformedResponse() {
        let (status, msg) = AuthError.malformedResponse.toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Malformed server response.")
    }

    func testConfiguration() {
        let (status, msg) = AuthError.configuration.toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Authentication configuration error. Please contact support.")
    }

    func testCancelled() {
        let (status, msg) = AuthError.cancelled.toAuthStatusAndMessage()
        XCTAssertEqual(status, .error)
        XCTAssertEqual(msg, "Request was cancelled.")
    }

}
