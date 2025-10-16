//
//  NoopAuthService.swift
//  Authentication
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

final class NoopAuthService: AuthService {
    init() {}
    func loginLocal(_ c: AuthCredantials) async throws -> AuthSession {
        throw AuthError.unimplemented("loginLocal")
    }
    func logout() async {}
    func beginIDP(_ provider: IDPProvider) async throws { throw AuthError.unimplemented("beginIDP") }
    func completeIDP() async throws -> AuthSession { throw AuthError.unimplemented("completeIDP") }
    func fetchCaptcha(for username: String?) async throws -> Captcha {
        throw AuthError.unimplemented("fetchCaptcha")
    }
    func verifyCaptcha(token: String, value: String) async throws -> CaptchaVerification {
        throw AuthError.unimplemented("verifyCaptcha")
    }
    func signup(_ request: SignupRequest) async throws -> SignupResult {
        throw AuthError.unimplemented("signup")
    }
}
