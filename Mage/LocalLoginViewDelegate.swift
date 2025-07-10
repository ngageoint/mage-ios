//
//  LocalLoginViewDelegate.swift
//  MAGE
//
//  Created by Brent Michalski on 7/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

@objc public protocol LocalLoginViewDelegate {
    func login(
        with parameters: [String: String],
        authenticationStrategy: String,
        complete: @escaping (_ status: AuthenticationStatus, _ errorString: String?) -> Void
    )
    
    func createAccount()
}
