//
//  LDAPAuth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public final class LDAPAuth: CredentialBasedModule {
    public required init(parameters: [AnyHashable: Any]?) { }
    public var defaultSigninPath: String { "auth/ldap/signin" }
    public var unauthorizedMessage: String { "Invalid LDAP credentials"}
}
