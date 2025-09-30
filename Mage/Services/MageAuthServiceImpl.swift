//
//  MageAuthServiceImpl.swift
//  MAGE
//
//  Created by Brent Michalski on 9/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication

final class MageAuthServiceImpl: AuthService {
    
    func fetchSignupCaptcha(username: String, backgroundHex: String) async throws -> SignupCaptcha {
        try await withCheckedThrowingContinuation { cont in
            MageAuthAPI.getSignupCaptcha(forUsername: username, background: backgroundHex) { token, base64, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                
                guard let token, let base64 else {
                    cont.resume(throwing: AuthError.server(status: 0, message: "Captcha not available"))
                    return
                }
                cont.resume(returning: SignupCaptcha(token: token, imageBase64: base64))
            }
        }
    }
    
    func submitSignup(_ req: SignupRequest, captchaText: String, token: String) async throws -> AuthSession {
        try await withCheckedThrowingContinuation { cont in
            MageAuthAPI.signup(withParameters: req.parameters, captchaText: captchaText, token: token) { http, error in
                if let error {
                    // TODO: Possibly use error mapper
                    let status = http?.statusCode ?? 0
                    
                    if let mapped = HTTPErrorMapper.map(status: status, headers: http?.allHeaderFields ?? [:], bodyData: nil) {
                        cont.resume(throwing: mapped)
                    } else {
                        cont.resume(throwing: error)
                    }
                    return
                }
                
                // Build a session from headers if present; otherwise create a nominal session.
                let headers = http?.allHeaderFields ?? [:]
                let token = (headers["X-Auth-Token"] as? String)
                ?? (headers["Authorization"] as? String)
                ?? "signed-up"
                
                cont.resume(returning: AuthSession(token: token))
            }
        }
    }
    
    func changePassword(_ req: ChangePasswordRequest) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            
            MageAuthAPI.changePassword(
                currentPassword: req.currentPassword,
                newPassword: req.newPassword,
                confirmedPassword: req.confirmNewPassword
            ) { http, error in
                if let error {
                    cont.resume(throwing: AuthError.server(status: http?.statusCode ?? 500,
                                                           message: error.localizedDescription))
                    return
                }
                
                let status = http?.statusCode ?? 0
                
                if let mapped = HTTPErrorMapper.map(status: status, headers: http?.allHeaderFields ?? [:], bodyData: nil) {
                    cont.resume(throwing: mapped)
                    return
                }
                cont.resume(returning: ())
            }
        }
    }
}


