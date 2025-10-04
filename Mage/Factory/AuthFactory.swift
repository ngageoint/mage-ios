//
//  AuthFactory.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication

enum AuthFactory {
    /// Primary entry point for callers that *already* know the kind.
    static func make(kind: StrategyKind,
                     parameters: [AnyHashable: Any]?,
                     store: AuthStore = KeychainAuthStore()) -> AuthenticationModule? {
        
        // Ensure DI is configured for every module we create
        let deps = makeDeps()
        deps.authStore = store
        
        switch kind {
        case .local:   return LocalAuth(parameters: parameters)
        case .ldap:    return LDAPAuth(parameters: parameters)
        case .offline: return OfflineAuth(parameters: parameters)
        case .idp:
            // Your coordinator will handle launching the web flow.
            return IdPAuth(parameters: parameters)
        }
    }
    
    /// Backward-compatible version
    static func make(strategy: String,
                     parameters: [AnyHashable: Any]?,
                     store: AuthStore = KeychainAuthStore()) -> AuthenticationModule? {
        guard let kind = StrategyKind(string: strategy) else { return nil }
        return make(kind: kind, parameters: parameters, store: store)
    }
    
    static func makeDeps() -> AuthDependencies {
        let deps = AuthDependencies.shared
        
        if deps.sessionStore == nil {
            deps.sessionStore = MageSessionStore.shared
        }
        
        return deps
    }
}
