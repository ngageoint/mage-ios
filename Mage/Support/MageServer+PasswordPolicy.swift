//
//  MageServer+PasswordPolicy.swift
//  MAGE
//
//  Created by Brent Michalski on 10/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication

public extension MageServer {
    
    /// Instance convenience; forwards to the static helper.
    func passwordPolicy(for kind: StrategyKind) -> PasswordPolicy? {
        Self.passwordPolicy(for: kind)
    }

    /// Pulls the password policy for a given auth strategy (e.g. .local)
    /// from the `/api` payload that was persisted into defaults.
    static func passwordPolicy(for kind: StrategyKind) -> PasswordPolicy? {
        guard
            let strategies = UserDefaults.standard.serverAuthenticationStrategies,
            let strategy = strategies[kind.rawValue] as? [String: Any],
            let settings = strategy["settings"] as? [String: Any],
            let dict = settings["passwordPolicy"] as? [String: Any]
        else { return nil }
        
        return PasswordPolicy(dict: dict)
    }
    
    /// Convenience for the common case used by sign-up/change-password
    static var localPasswordPolicy: PasswordPolicy? {
        passwordPolicy(for: .local)
    }
}
