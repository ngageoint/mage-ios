//
//  CredentialBasedModule.swift
//  Authentication
//
//  Created by Brent Michalski on 9/22/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
//  Purpose: Default login implementation for username/password modules
//  (Local, LDAP, IdP). Modules only provide endpoint path + copy.
//

import Foundation

public protocol CredentialBasedModule: AuthenticationModule {
    /// Default endpoint path for this module (e.g., "/auth/local/signin").
    var defaultSigninPath: String { get }
    
    /// Module-specific wording for invalid credentials.
    var unauthorizedMessage: String { get }
}

public extension CredentialBasedModule {
    func login(withParameters params: [AnyHashable: Any],
               complete: @escaping (AuthenticationStatus, String?) -> Void) {
        
        // Allow per-request override of the path (optiona)
        let path = (params["signinPath"] as? String) ?? defaultSigninPath
        
        guard
            let req = CredentialInput.make(
                from: params,
                path: path,
                defaultBase: AuthDefaults.baseServerUrl
            )
                   else {
        complete(.unableToAuthenticate, "Missing credentials or server URL!")
        return
    }
        
        CredentialLogin.perform(
            url: req.url,
            username: req.username,
            password: req.password,
            unauthorizedMessage: unauthorizedMessage,
            complete: complete
        )
    }
}
