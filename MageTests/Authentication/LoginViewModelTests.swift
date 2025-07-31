//
//  LoginViewModelTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 7/31/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

class MockLoginDelegateSwiftUI: LoginDelegate {
    var loginCalled = false
    var loginParameters: [AnyHashable: Any]?
    var authenticationStrategy: String?
    var createAccountCalled = false
    var changeServerURLCalled = false
    var statusToReturn: AuthenticationStatus = .UNABLE_TO_AUTHENTICATE
    var errorStringToReturn: String? = "Login failed"
    
    func login(
        withParameters parameters: [AnyHashable: Any]!,
        withAuthenticationStrategy: String,
        complete: ((AuthenticationStatus, String?) -> Void)!
    ) {
        loginCalled = true
        loginParameters = parameters
        authenticationStrategy = withAuthenticationStrategy
        complete?(statusToReturn, errorStringToReturn)
    }
    
    func changeServerURL() { changeServerURLCalled = true }
    func createAccount() { createAccountCalled = true }
}


final class LoginViewModelTests: XCTestCase {
//    var server: MageServer!
//    var delegate: MockLoginDelegateSwiftUI!
//    var strategy: [String: Any] = [
//        "identifier": "local",
//        "strategy": ["title", "Local Login", "name": "Local", "type": "local"],
//    ]
//    let dummyUser = User()
//    
//    override func setUp() {
//        super.setUp()
//        
//        delegate = MockLoginDelegateSwiftUI()
//        viewModel = LoginViewModel(server: server, strategy: <#T##[String : Any]#>, delegate: <#T##LoginDelegate?#>, user: <#T##User?#>)
//    }

    
}
