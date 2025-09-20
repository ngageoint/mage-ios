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
                if let error {
                    cont.resume(throwing: AuthError.server(status: 500, message: error.localizedDescription))
                    return
                }
                guard let token, let captcha else {
                    cont.resume(throwing: AuthError.invalidInput(message: "Missing captcha or token"))
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
            "confirmPasword": req.confirmPassword,  // TODO: BRENT - double check the proper term (had passwordconfirm)
            "captcha": captchaText
        ]
        
        return try await withCheckedThrowingContinuation { cont in
            MageAuthAPI.completeSignup(withParameters: params, token: token) { http, body, error in
                if let error {
                    cont.resume(throwing: AuthError.server(status: http?.statusCode ?? 500, message: error.localizedDescription))
                    return
                }
                
                let status = http?.statusCode ?? 0
                
                if let mapped = HTTPErrorMapper.map(status: status, headers: http?.allHeaderFields ?? [:], bodyData: body) {
                    cont.resume(throwing: mapped)
                    return
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


