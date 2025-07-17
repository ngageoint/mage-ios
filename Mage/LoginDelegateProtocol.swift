//
//  LoginDelegateProtocol.swift
//  MAGE
//
//  Created by Brent Michalski on 7/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public protocol LoginDelegate {
    func login(
        withParameters parameters: [String: Any],
        withAuthenticationStrategy authenticationStrategy: String,
        complete: @escaping (_ authenticationStatus: AuthenticationStatus, _ errorString: String?) -> Void
    )
    func changeServerURL()
    func createAccount()
}

