//
//  LdapLoginStrategyNextGen.swift
//  MAGE
//
//  Created by Brent Michalski on 7/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct LdapLoginStrategyNextGen: LoginStrategyNextGen {
    var displayName: String { "LDAP" }
    let server: MageServer
    
    func login(username: String, password: String) async throws -> UserNextGen {
        // TODO: Implement ACTUAL LDAP auth
        
        if username == "ldapuser" && password == "ldappass" {
            return UserNextGen(username: username)
        }
        throw NSError(domain: "LDAPLogin", code: 401, userInfo: [NSLocalizedDescriptionKey : "Invalid LDAP credentials"])
    }
    
}
