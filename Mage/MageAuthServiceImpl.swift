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
    
    func signup(_ req: SignupRequest) async throws -> AuthSession {
        throw AuthError.server("Signup requires CAPTCHA on this server.")
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


