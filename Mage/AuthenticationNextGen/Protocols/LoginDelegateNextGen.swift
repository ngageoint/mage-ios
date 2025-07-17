//
//  LoginDelegateNextGen.swift
//  MAGE
//
//  Created by Brent Michalski on 7/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol LoginDelegateNextGen: AnyObject {
    /// Called whenever an authentication attempt finishes (success, error, etc).
    /// - Parameters:
    ///   - status: The result of the attempt.
    ///   - user: The authenticated user, if successful.
    ///   - error: Any error that occurred.
    func authenticationDidFinish(
        status: AuthenticationStatusNextGen,
        user: UserNextGen?,
        error: Error?
    )

    /// (Optional) Called when user requests signup (if you want explicit event)
    func createAccount()
}
