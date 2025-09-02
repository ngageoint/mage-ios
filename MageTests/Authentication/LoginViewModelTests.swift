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
    
    final class SpyLoginDelegate: NSObject, LoginDelegate {
        func changeServerURL() {
            print("Spy changeServerURL() called")
        }
        
        func createAccount() {
            print("Spy createAccount() called")
        }
        
        var lastParams: [AnyHashable: Any]?
        var lastStrategy: String?
        var completed: (AuthenticationStatus, String?)?
        
        func login(withParameters parameters: [AnyHashable: Any]!,
                   withAuthenticationStrategy authenticationStrategy: String!,
                   complete: ((AuthenticationStatus, String?) -> Void)!) {
            lastParams = parameters
            lastStrategy = authenticationStrategy
            
            // Simulate success immediately
            complete(.AUTHENTICATION_SUCCESS, nil)
        }
    }
    
    func test_loginTapped_buildsLocalPayload_andCallsDelegate() {
        let spy = SpyLoginDelegate()
        let vm = LoginViewModel(strategy: ["identifier": "local", "name": "Local"], delegate: spy)
        
        vm.username = "username"
        vm.password = "password"
        vm.loginTapped()
        
        XCTAssertEqual(spy.lastStrategy, "local")
        XCTAssertEqual(spy.lastParams?["username"] as? String, "username")
        XCTAssertEqual(spy.lastParams?["password"] as? String, "password")
        
        XCTAssertEqual((spy.lastParams?["strategy"] as? [String: Any])?["identifier"] as? String, "local")
        XCTAssertNotNil(spy.lastParams?["uid"])
        XCTAssertNotNil(spy.lastParams?["appVersion"])

        
    }
    
    
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
