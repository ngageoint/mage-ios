//
//  LoginStrategy.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

/// Enum to classify login strategies
enum LoginStrategyType: String {
    case local
    case ldap
    case idp
    case unknown

    init(identifier: String) {
        switch identifier {
        case "local": self = .local
        case "ldap": self = .ldap
        case _ where identifier.hasPrefix("oauth"): self = .idp
        default: self = .unknown
        }
    }
}

/// A Swift-friendly model for authentication strategy
struct LoginStrategy: Identifiable {
    let id: String
    let type: LoginStrategyType
    let parameters: [String: Any]

    init?(dictionary: [String: Any]) {
        guard let id = dictionary["identifier"] as? String,
              let params = dictionary["strategy"] as? [String: Any] else {
            return nil
        }
        
        self.id = id
        self.parameters = params
        
        if let typeString = params["type"] as? String {
            self.type = LoginStrategyType(identifier: typeString)
        } else {
            self.type = id == "local" ? .local : .unknown
        }
    }
    
//    init(identifier: String, parameters: [AnyHashable: Any]) {
//        self.id = identifier
//        self.parameters = parameters
//        self.type = LoginStrategyType(identifier: identifier)
//    }

    static func loadAllFromUserDefaults() -> [LoginStrategy] {
        guard let strategies = UserDefaults.standard.dictionary(forKey: "serverAuthenticationStrategies") as? [String: [AnyHashable: Any]] else {
            return []
        }
        return strategies.compactMap { LoginStrategy(dictionary: ["identifier": $0.key, "strategy": $0.value]) }
    }
}
