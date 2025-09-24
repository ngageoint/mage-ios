//
//  AuthDependencies.swift
//  MAGE
//
//  Created by Brent Michalski on 9/19/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation

public final class AuthDependencies {
    public static let shared = AuthDependencies()
    public var authService: AuthService?
    public var sessionStore: SessionStore?
    public var http: HTTPPerforming = HTTPLoginPerformer()
    public var authStore: AuthStore!
    private init() {}
}

#if DEBUG
extension AuthDependencies {
    public static func resolvedForDebug(
        http: HTTPPerforming = HTTPLoginPerformer()
    ) -> AuthDependencies {
        let authDependencies = AuthDependencies.shared
        authDependencies.http = http
        return authDependencies
    }
}
#endif

public extension AuthDependencies {
    var requireAuthStore: AuthStore {
        guard let store = authStore else { fatalError("AuthDependencies.authStore is not configured") }
        return store
    }
 
    var requireSessionStore: SessionStore {
        guard let store = sessionStore else { fatalError("AuthDependencies.sessionStore is not configured") }
        return store
    }
    
    var requireAuthService: AuthService {
        guard let store = authService else { fatalError("AuthDependencies.authService is not configured") }
        return store
    }
}
