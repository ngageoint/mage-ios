//
//  AuthStrategy.swift
//  Authentication
//
//  Created by Brent Michalski on 9/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum AuthStrategy: Equatable {
    case local
    case ldap
    case idp(provider: String?)
    case offline
    
    public static func from(_ raw: String?) -> AuthStrategy {
        let s = (raw ?? "").lowercased()
        
        switch s {
        case "local", "userpass", "usernamepassword":
            return .local
        case "ldap":
            return .ldap
        case "offline":
            return .offline
        case "oidc", "sso", "idp", "saml", "geoaxis", "geoaxisconnect":
            return .idp(provider: s)
        default:
            // Treat unknown strategy names as IdP so the flow still works
            return .idp(provider: s.isEmpty ? nil : s)
        }
    }
}
