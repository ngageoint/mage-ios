//
//  AuthService.swift
//  Authentication
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol AuthService {
    func loginLocal(_ credentials: AuthCredantials) async throws -> AuthSession
    func logout() async
    
    func beginIDP(_ provider: IDPProvider) async throws
    func completeIDP() async throws -> AuthSession
    
    func fetchCaptcha(for username: String?) async throws -> Captcha
    func verifyCaptcha(token: String, value: String) async throws -> CaptchaVerification
    func signup(_ request: SignupRequest) async throws -> SignupResult
}
