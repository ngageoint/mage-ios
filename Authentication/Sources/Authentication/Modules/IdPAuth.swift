//
//  IdPAuth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public final class IdPAuth: CredentialBasedModule {
    public required init(parameters: [AnyHashable: Any]?) { }
    
    public func canHandleLogin(toURL url: String) -> Bool { true }
    
    public var defaultSigninPath: String { "auth/idp/signin" }
    public var unauthorizedMessage: String { "Invalid IdP credentials"}
}
