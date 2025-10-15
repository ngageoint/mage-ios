//
//  AuthenticationModule.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public typealias AuthParams = [AnyHashable: Any]

/// Status codes used across all modules.
@objc public enum AuthenticationStatus: Int, Sendable {
    case success                // -> AuthenticationStatusSuccess
    case error                  // -> AuthenticationStatusError
    case unableToAuthenticate   // -> AuthenticationStatusUnableToAuthenticate
    case registrationSuccess    // -> AuthenticationStatusRegistrationSuccess
    case accountCreationSuccess // -> AuthenticationStatusAccountCreationSuccess
}

/// All auth modules (local/ldap/offline/idp) conform to this.
public protocol AuthenticationModule: AnyObject {
    /// Factory-style init. Params come from the server / strategy record.
    init(parameters: [AnyHashable: Any]?)
    
    /// Whether this module can handle a login for the given base URL.
    func canHandleLogin(toURL url: String) -> Bool
    
    /// Primary login entry point (local/ldap/offline).
    /// - Parameters:
    ///   - params: Login form fields (username/password/etc.)
    ///   - complete: Completion with status and optional message.
    func login(withParameters params: [AnyHashable: Any],
               complete: @escaping (AuthenticationStatus, String?) -> Void)
    
    /// Optional IdP completion hook after Safari redirect.
    /// Modules that don’t use IdP can ignore; default impl below returns `.error`.
    func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void)
}

// MARK: - Default behaviors & conveniences
public extension AuthenticationModule {
    /// Non-IdP modules don't need to implement this.
    func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        complete(.error, "finishLogin is not supported by this module.", nil)
    }
    
    /// Async convenience for login
    func login(with parameters: [AnyHashable: Any]) async -> (AuthenticationStatus, String?) {
        await withCheckedContinuation { cont in
            login(withParameters: parameters) { status, message in
                cont.resume(returning: (status, message))
            }
        }
    }
    
    /// Async convenience of IdP completion.
    func finishLogin() async -> (AuthenticationStatus, String?, String?) {
        await withCheckedContinuation { cont in
            finishLogin { s, m, d in cont.resume(returning: (s, m, d)) }
        }
    }
    
    func login(with parameters: [String: Any],
               complete: @escaping (AuthenticationStatus, String?) -> Void) {
        login(withParameters: parameters as [AnyHashable: Any], complete: complete)
    }
}
