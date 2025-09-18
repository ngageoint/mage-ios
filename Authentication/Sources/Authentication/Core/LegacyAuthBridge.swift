////
////  LegacyAuthBridge.swift
////  Authentication
////
////  Created by Brent Michalski on 9/16/25.
////  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
////
//
//import Foundation
//
//@objc public protocol AuthenticationProtocol {
//    init(parameters: [AnyHashable: Any]?)
//    var parameters: [AnyHashable: Any] { get }
//    func canHandleLogin(toURL url: String) -> Bool
//    func login(withParameters loginParameters: [AnyHashable: Any],
//               complete: @escaping (AuthenticationStatus, String?) -> Void)
//    func finishLogin(_ complete: @escaping (AuthenticationStatus, String?, String?) -> Void)
//}
//
//@objcMembers
//public final class Authentication: NSObject {
//    /// Factory used by legacy callers... Wire to our real implementations
//    public class func authenticationModule(forStrategy strategy: String,
//                                           parameters: [AnyHashable: Any]?) -> AuthenticationProtocol? {
//        
//        // TODO: return concrete implementations bases on `strategy`
//        // e.g. LocalAuthentication(parameters: _)...
//        return AuthFactory.shared.make(strategy: strategy, parameters: parameters)
//    }
//    
//    public class func isLocalStrategy(_ s: String) -> Bool { s == "local" }
//    public class func isLdapStrategy(_ s: String) -> Bool { s == "ldap" }
//    public class func isIdpStrategy(_ s: String) -> Bool {
//        let idp = ["idp", "oauth", "oauth2", "oidc", "saml", "geoaxiosconnect"]
//        return idp.contains(s.lowercased())
//    }
//    public class func isOfflineStrategy(_ s: String) -> Bool { s == "offline" }
//}
