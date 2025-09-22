//
//  IdPAuth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public final class IdPAuth: AuthenticationModule {
    private let params: [AnyHashable: Any]?
    public required init(parameters: [AnyHashable: Any]?) { self.params = parameters }
    
    public func canHandleLogin(toURL url: String) -> Bool { true }
    
    public func login(withParameters params: [AnyHashable : Any], complete: @escaping (AuthenticationStatus, String?) -> Void) {
        let path = (params["signinPath"] as? String) ?? "/auth/idp/signin"
        
        guard
            let req = CredentialInput.make(
                from: params,
                path: path,
                defaultBase: AuthDefaults.baseServerUrl
                )
        else {
            complete(.unableToAuthenticate, "Missing credentials or server URL")
            return
        }
        
        CredentialLogin.perform(
            url: req.url,
            username: req.username,
            password: req.password,
            unauthorizedMessage: "Invalid IdP credentials.",
            complete: complete
        )
    }
    
    public func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        complete(.success, nil, nil)
    }
}
