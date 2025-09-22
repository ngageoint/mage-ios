//
//  LocalAuth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

// MARK: - Local (username/password)
public final class LocalAuth: CredentialBasedModule {
    public required init(parameters: [AnyHashable: Any]?) { }
   
    public func canHandleLogin(toURL url: String) -> Bool { true }
    
    // CredentialBasedModule requirements:
    public var defaultSigninPath: String { "/auth/local/signin" }
    public var unauthorizedMessage: String { "Invalid username or password." }
}
