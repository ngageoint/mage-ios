//
//  LocalLoginStrategyNextGen.swift
//  MAGE
//
//  Created by Brent Michalski on 7/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct LocalLoginStrategyNextGen: LoginStrategyNextGen {
    let displayName: String = "Local Login"
    
    func login(username: String, password: String) async throws -> UserNextGen {
        // TODO: - Add our REAL implementation here

        if username == "admin" && password == "password" {
            return UserNextGen(username: username)
        } else {
            throw NSError(domain: "LocalLogin", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
    }
}
