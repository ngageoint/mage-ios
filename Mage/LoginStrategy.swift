//
//  LoginStrategy.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

/// Enum to classify login strategies
public enum LoginStrategyType: String {
    case local
    case ldap
    case idp
    case unknown

    public static func from(identifier: String) -> LoginStrategyType {
        switch identifier {
        case "local": return .local
        case "ldap": return .ldap
        case _ where identifier.hasPrefix("oauth"): return .idp
        default: return .unknown
        }
    }
    
//    init(identifier: String) {
//        switch identifier {
//        case "local": self = .local
//        case "ldap": self = .ldap
//        case _ where identifier.hasPrefix("oauth"): self = .idp
//        default: self = .unknown
//        }
//    }
}

@objcMembers
public class LoginStrategy: NSObject, Identifiable {
    public let id: String
    public let type: LoginStrategyType
    public let parameters: [String: Any]

    public init(id: String, parameters: [String: Any] = [:]) {
        self.id = id
        self.parameters = parameters
        self.type = LoginStrategyType.from(identifier: id)
    }

    public convenience init?(dictionary: [String: Any]) {
        guard let id = dictionary["identifier"] as? String else {
            return nil
        }
        let params = dictionary["strategy"] as? [String: Any] ?? [:]
        self.init(id: id, parameters: params)
    }
    
//    init?(dictionary: [String: Any]) {
//        guard let id = dictionary["identifier"] as? String,
//              let params = dictionary["strategy"] as? [String: Any] else {
//            return nil
//        }
//        
//        self.id = id
//        self.parameters = params
//        
//        if let typeString = params["type"] as? String {
//            self.type = LoginStrategyType(identifier: typeString)
//        } else {
//            self.type = id == "local" ? .local : .unknown
//        }
//    }


    static func loadAllFromUserDefaults() -> [LoginStrategy] {
        guard let strategies = UserDefaults.standard.dictionary(forKey: "serverAuthenticationStrategies") as? [String: [AnyHashable: Any]] else {
            return []
        }
        return strategies.compactMap { LoginStrategy(dictionary: ["identifier": $0.key, "strategy": $0.value]) }
    }
}
