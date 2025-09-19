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
    private init() {}
}

#if DEBUG
extension AuthDependencies {
    func resolvedForDebug() -> AuthDependencies {
        var copy = self
        if copy.authService == nil { copy.authService = PreviewAuthService() }
        if copy.sessionStore == nil { copy.sessionStore = PreviewSessionStore() }
        return copy
    }
}
#endif
