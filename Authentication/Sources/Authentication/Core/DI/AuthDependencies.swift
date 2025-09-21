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
    private init() {}
}

#if DEBUG
extension AuthDependencies {
    public static func resolvedForDebug(
        http: HTTPPerforming = HTTPLoginPerformer()
    ) -> AuthDependencies {
        let d = AuthDependencies.shared
        d.http = http
        return d
    }
}
#endif
