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
            MageAuthAPI.getSignupCaptcha(forUsername: username, background: backgroundHex) { token, captcha, error in
                if let error { cont.resume(throwing: AuthError.server(error.localizedDescription)); return }
                guard let token, let captcha else {
                    cont.resume(throwing: AuthError.server("Missing captcha or token"))
                    return
                }
                cont.resume(returning: SignupCaptcha(token: token, imageBase64: captcha))
            }
        }
    }
    
    func submitSignup(_ req: SignupRequest, captchaText: String, token: String) async throws -> AuthSession {
        let params: [String: Any] = [
            "username": req.username,
            "displayName": req.displayName,
            "email": req.email,
            "password": req.password,
            "passwordconfirm": req.confirmPassword,
            "captcha": captchaText
        ]
        
        return try await withCheckedThrowingContinuation { cont in
            MageAuthAPI.completeSignup(withParameters: params, token: token) { http, body, error in
                if let error {
                    cont.resume(throwing: AuthError.server(error.localizedDescription))
                    return
                }
                
                let status = http?.statusCode ?? 0
                switch status {
                case 200, 201:
                    // Adjust i server returns a session token on success
                    cont.resume(returning: AuthSession(token: "signup-created"))
                case 401:
                    cont.resume(throwing: AuthError.unauthorized)
                case 429:
                    cont.resume(throwing: AuthError.rateLimited)
                default:
                    let msg = body.flatMap { String(data: $0, encoding: .utf8) } ?? "Signup failed (\(status))"
                    cont.resume(throwing: AuthError.server(msg))
                }
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
                    cont.resume(throwing: AuthError.server(error.localizedDescription))
                    return
                }
                
                let status = http?.statusCode ?? 0
                
                switch status {
                case 200, 204:
                    cont.resume(returning: ())  // Return void to the continuation
                case 401:
                    cont.resume(throwing: AuthError.unauthorized)
                case 429:
                    cont.resume(throwing: AuthError.rateLimited)
                default:
                    cont.resume(throwing: AuthError.server("Password change failed (\(status))"))
                }
            }
        }
    }
}


