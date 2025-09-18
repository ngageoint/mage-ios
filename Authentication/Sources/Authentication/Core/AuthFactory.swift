//
//  AuthFactory.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum AuthFactory {
    public static func make(strategy: String,
                            parameters: [AnyHashable: Any]?,
                            store: AuthStore = KeychainAuthStore()
    ) -> AuthenticationModule? {
        switch strategy.lowercased() {
        case "local":   return LocalAuth(parameters: parameters)
        case "ldap":    return LDAPAuth(parameters: parameters)
        case "offline": return OfflineAuth(parameters: parameters, store: store)
            
        // Treat all IdP variants the same here; your coordinator will launch the web flow.
        case "idp", "oidc", "saml", "geoaxisconnect":
            return IdPAuth(parameters: parameters)
        default:
            return nil
        }
    }
}
