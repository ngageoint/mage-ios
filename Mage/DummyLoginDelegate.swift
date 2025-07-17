//
//  DummyLoginDelegate.swift
//  MAGE
//
//  Created by Brent Michalski on 7/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


class DummyLoginDelegate: NSObject, LoginDelegate {
    func login(withParameters parameters: [String : Any], withAuthenticationStrategy authenticationStrategy: String, complete: @escaping (AuthenticationStatus, String?) -> Void) {
        complete(.AUTHENTICATION_SUCCESS, nil)
    }
    
//    func login(withParameters parameters: [AnyHashable : Any]!, withAuthenticationStrategy authenticationStrategy: String!, complete: ((AuthenticationStatus, String?) -> Void)!) {
//        complete(.AUTHENTICATION_SUCCESS, nil)
//    }
    
    func changeServerURL() {
        print("changeServerURL() called")
    }
    
//    func loginWithParameters(
//        _ parameters: NSDictionary,
//        withAuthenticationStrategy authenticationStrategy: NSString,
//        complete: @escaping (AuthenticationStatus, NSString?) -> Void
//    ) {
//        complete(.AUTHENTICATION_SUCCESS, nil)
//    }

    func createAccount() {
        print("createAccount() called")
    }
}
