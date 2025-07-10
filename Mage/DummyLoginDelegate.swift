//
//  DummyLoginDelegate.swift
//  MAGE
//
//  Created by Brent Michalski on 7/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


class DummyLoginDelegate: NSObject, LocalLoginViewDelegate {
    func login(with parameters: [String : String], authenticationStrategy withAuthenticationStrategy: String, complete: @escaping (AuthenticationStatus, String?) -> Void) {
        complete(.AUTHENTICATION_SUCCESS, nil)
    }

    func createAccount() {
        print("createAccount() called")
    }
}
