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
            MageAuthAPI.requestSignupCaptcha(forUsername: username, background: backgroundHex) { token, captcha, error in
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
        
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            MageAuthAPI.completeSignup(withParameters: params, token: token) { http, body, error in
                if let error {
                    let status = http?.statusCode ?? -1
                    switch status {
                    case 401: cont.resume(throwing: AuthError.unauthorized)
                    case 429: cont.resume(throwing: AuthError.rateLimited)
                    case 0: cont.resume(throwing: AuthError.network)
                    default:
                        let msg = body.flatMap { String(data: $0, encoding: .utf8) } ?? error.localizedDescription
                        cont.resume(throwing: AuthError.server(msg))
                    }
                    return
                }
                cont.resume(returning: ())
            }
        }
        
        // After server says OK, you may want automatic session/login
        // For now, mirror legacy UX: return a "pending" session or require manual login.
        return AuthSession(token: "signup-created")  // placeholder if your server returns a token; swap when available
    }
    
    
    func changePassword(_ req: ChangePasswordRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            MageAuthAPI.changePassword(
                withCurrent: req.currentPassword,
                newPassword: req.newPassword,
                confirmNewPassword: req.confirmNewPassword
            ) { http, errorBody, error in
                if let error {
                    let status = http?.statusCode ?? -1
                    switch status {
                    case 401: continuation.resume(throwing: AuthError.unauthorized)
                    case 429: continuation.resume(throwing: AuthError.rateLimited)
                    case 0:   continuation.resume(throwing: AuthError.network)
                    default:
                        let msg = (errorBody.flatMap { String(data: $0, encoding: .utf8) }) ?? error.localizedDescription
                        continuation.resume(throwing: AuthError.server(msg))
                    }
                    return
                }
                continuation.resume(returning: ()) // Success
            }
        }
    }
}


