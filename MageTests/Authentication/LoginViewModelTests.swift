//
//  LoginViewModelTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 7/31/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class LoginViewModelTests: XCTestCase {
    func testLoginTapped_withValidInput_callsDelegate() {
        let delegate = MockLoginDelegateSwiftUI()
        let vm = LoginViewModel(strategy: ["identifier": "local"], delegate: delegate)
        vm.username = "vm.username"
        vm.password = "vm.password"
        
        vm.loginTapped()
        
        XCTAssertTrue(delegate.didLogin)
        XCTAssertEqual(delegate.receivedStrategy, "local")
        XCTAssertTrue(delegate.completeCalled)
        XCTAssertNil(vm.errorMessage)
    }
    
    func testLoginTapped_withMissingInput_setsError() {
        let vm = LoginViewModel(strategy: ["identifier": "local"], delegate: nil)
        vm.username = ""
        vm.password = ""
        
        vm.loginTapped()
        
        XCTAssertEqual(vm.errorMessage, "Username and password are required.")
    }

    func testSignupTapped_callsDelegate() {
        class Delegate: NSObject, LoginDelegate {
            var didCallCreate = false
            func login(withParameters: [AnyHashable : Any], withAuthenticationStrategy: String, complete: @escaping (AuthenticationStatus, String?) -> Void) {}
            func changeServerURL() { }
            func createAccount() { didCallCreate = true }
        }
        let delegate = Delegate()
        let vm = LoginViewModel(strategy: ["identifier": "local"], delegate: delegate)
        vm.signupTapped()
        XCTAssertTrue(delegate.didCallCreate)
    }
    
    func testLoginTappedWithNilDelegateDoesNotCrash() {
        let vm = LoginViewModel(strategy: ["identifier": "local"], delegate: nil)
        vm.username = "testuser"
        vm.password = "testpass"
        XCTAssertNoThrow(vm.loginTapped())
    }
    
}
