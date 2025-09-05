//
//  AppBootstrap.swift
//  Authentication
//
//  Created by Brent Michalski on 9/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public final class AppBootstrap: NSObject {
    
    /// Called from Obj-C AppDelegate. Creates and registers the concrete AuthService.
    @objc public static func configureDependencies() {
        // TODO: Replace this with our implementation
        // Example: if we have a concrete service in Authentication:
        // let service = MageAuthService(/* inject network/session here */)
        
        // Temporary placeholder
        struct NotConfiguredAuthService: AuthService {
            func signup(_ req: SignupRequest) async throws -> AuthSession { throw AuthError.network }
            func changePassword(_ req: ChangePasswordRequest) async throws { throw AuthError.network }
        }
        
        let service: AuthService = NotConfiguredAuthService()
        
        AuthDependencies.shared.authService = service
    }
}
