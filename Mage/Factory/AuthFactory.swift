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
    /// Ensure shared DI is in a valid state before creating modules
    static func makeDeps() -> AuthDependencies {
        let deps = AuthDependencies.shared
        if deps.sessionStore == nil {
            deps.sessionStore = MageSessionStore.shared
        }
        if deps.authService == nil {
            deps.configureAuthServiceIfNeeded(baseURL: MageServer.baseURL())
        }
        return deps
    }
    
    static func make(kind: StrategyKind,
                     parameters: [AnyHashable: Any]?,
                     store: AuthStore = KeychainAuthStore()) -> AuthenticationModule? {
        
        let deps = makeDeps()
        deps.authStore = store
        
        switch kind {
        case .local:    return LocalAuth(parameters: parameters)
        case .ldap:     return LDAPAuth(parameters: parameters)
        case .offline:  return OfflineAuth(parameters: parameters)
        case .idp:      return IdPAuth(parameters: parameters)
        }
    }
    
    static func make(strategy: String,
                     parameters: [AnyHashable: Any]?,
                     store: AuthStore = KeychainAuthStore()) -> AuthenticationModule? {
        guard let kind = StrategyKind(string: strategy) else { return nil }
        return make(kind: kind, parameters: parameters, store: store)
    }
}
