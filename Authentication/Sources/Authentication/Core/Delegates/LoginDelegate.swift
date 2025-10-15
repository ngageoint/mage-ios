//
//  LoginDelegate.swift
//  Authentication
//
//  Created by Brent Michalski on 9/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation

@MainActor
@objc public protocol LoginDelegate: AnyObject {
    @objc func changeServerURL()
    
    @objc(loginWithParameters:withAuthenticationStrategy:complete:)
    func login(withParameters parameters: NSDictionary,
               withAuthenticationStrategy authenticationStrategy: String,
               complete: @escaping (_ status: AuthenticationStatus, _ errorString: String?) -> Void)
    
    @objc func createAccount()
    
    @objc(signinForStrategy:)
    func signinForStrategy(_ strategy: NSDictionary)
}
