//
//  MockAuthenticationCoordinatorDelegate.swift
//  MAGE
//
//  Created by Brent Michalski on 3/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation

class MockAuthenticationCoordinatorDelegate: NSObject, AuthenticationDelegate {
    var authenticationSuccessfulCalled = false
    var couldNotAuthenticateCalled = false
    var changeServerUrlCalled = false
    var onAuthenticationSuccessful: (() -> Void)?
    
    func authenticationSuccessful() {
        authenticationSuccessfulCalled = true
        onAuthenticationSuccessful?()
    }
    
    func couldNotAuthenticate() {
        couldNotAuthenticateCalled = true
    }
    
    func changeServerUrl() {
        changeServerUrlCalled = true
    }
}
