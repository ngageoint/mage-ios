//
//  MockLoginDelegateSwiftUI.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import XCTest
@testable import MAGE
import Authentication

@MainActor
@objcMembers
final class MockLoginDelegateSwiftUI: NSObject, LoginDelegate {
    
    struct LoginCall {
        let params: NSDictionary
        let strategy: String
    }

    // Observability for tests
    private(set) var loginCalls: [LoginCall] = []
    private(set) var changeServerURLCalled = false
    private(set) var createAccountCalled = false
    private(set) var signinStrategies: [NSDictionary] = []
    
    /// Configure what `login` should return
    var nextStatus: AuthenticationStatus = .success
    var nextError: String? = nil

    // MARK: LoginDelegate
    func changeServerURL() {
        changeServerURLCalled = true
    }
    
    
    @objc(loginWithParameters:withAuthenticationStrategy:complete:)
    func login(withParameters parameters: NSDictionary,
               withAuthenticationStrategy strategy: String,
               complete: @escaping (_ status: AuthenticationStatus, _ errorString: String?) -> Void) {
        loginCalls.append(.init(params: parameters, strategy: strategy))
        complete(nextStatus, nextError)
    }
    
    func createAccount() {
        createAccountCalled = true
    }

    @objc(signinForStrategy:)
    func signinForStrategy(_ strategy: NSDictionary) {
        signinStrategies.append(strategy)
    }
}

