//
//  NoopAuthService.swift
//  Authentication
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public final class NoopAuthService: AuthService {
    public init() {}
    public func loginLocal(_ c: AuthCredantials) async throws -> AuthSession {
        throw AuthError.unimplemented("loginLocal")
    }
    public func logout() async {}
    public func beginIDP(_ provider: IDPProvider) async throws { throw AuthError.unimplemented("beginIDP") }
    public func completeIDP() async throws -> AuthSession { throw AuthError.unimplemented("completeIDP") }
    public func fetchCaptcha(for username: String?) async throws -> Captcha {
        throw AuthError.unimplemented("fetchCaptcha")
    }
    public func verifyCaptcha(token: String, value: String) async throws -> CaptchaVerification {
        throw AuthError.unimplemented("verifyCaptcha")
    }
    public func signup(_ request: SignupRequest) async throws -> SignupResult {
        throw AuthError.unimplemented("signup")
    }
}
