//
//  AuthStatusAndLoginDelegate.swift
//  Authentication
//
//  Created by Brent Michalski on 9/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc(AuthenticationStatus)
public enum AuthenticationStatus: Int {
    case success                // -> AuthenticationStatusSuccess
    case error                  // -> AuthenticationStatusError
    case unableToAuthenticate   // -> AuthenticationStatusUnableToAuthenticate
    case registrationSuccess    // -> AuthenticationStatusRegistrationSuccess
    case accountCreationSuccess // -> AuthenticationStatusAccountCreationSuccess
}

@objc(LoginDelegate)
public protocol LoginDelegate {
    // Keep Obj-C selector exactly: loginWithParameters:withAuthenticationStrategy:complete:
    @objc(loginWithParameters:withAuthenticationStrategy:complete:)
    func login(withParameters parameters: [AnyHashable: Any],
               withAuthenticationStrategy authenticationStrategy: String,
               complete: @escaping (_ status: AuthenticationStatus, _ errorString: String?) -> Void)
    
    @objc func changeServerURL()
    @objc func createAccount()
}
