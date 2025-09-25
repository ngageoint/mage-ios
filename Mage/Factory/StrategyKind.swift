//
//  StrategyKind.swift
//  MAGE
//
//  Created by Brent Michalski on 9/22/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum StrategyKind: String {
    case local
    case ldap
    case idp
    case offline
    
    /// Failable initializer that tolerates common aliases/variants
    public init?(string: String) {
        switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "local":
            self = .local
        case "ldap":
            self = .ldap
        case "offline":
            self = .offline
        case "saml", "google", "oauth", "geoaxis", "openidconnect":
            self = .idp
        default:
            return nil
        }
    }
}
