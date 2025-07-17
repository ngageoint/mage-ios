//
//  LoginViewModelNextGenTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 7/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Testing
@testable import MAGE

// Mocks
final class MockLoginDelegateNextGen: LoginDelegateNextGen {
    var lastStatus: AuthenticationStatusNextGen?
    var lastUser: UserNextGen?
    var lastError: Error?
    var signupCalled = false
    
    func authenticationDidFinish(status: AuthenticationStatusNextGen, user: UserNextGen?, error: Error?) {
        lastStatus = status
        lastUser = user
        lastError = error
    }
    func createAccount() {
        signupCalled = true
    }
}

struct MockLoginStrategyNextGen: LoginStrategyNextGen {
    var displayName: String { "Local" }
    var shouldSucceed = true
    
    func login(username: String, password: String) async throws -> UserNextGen {
        if shouldSucceed && username == "admin" && password == "password" {
            return UserNextGen(username: username)
        } else {
            throw NSError(domain: "LocalLogin", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
    }
}


@Suite
struct LoginViewModelNextGenTests {
    @Test
    @MainActor
    func testLoginSuccess() async {
        let delegate = MockLoginDelegateNextGen()
        let strategy = MockLoginStrategyNextGen(shouldSucceed: true)
        let viewModel = LoginViewModelNextGen(strategies: [strategy], delegate: delegate)
        viewModel.username = "admin"
        viewModel.password = "password"
        
        await viewModel.login(using: strategy)
        
        #expect(delegate.lastStatus == .success)
        #expect(delegate.lastUser?.username == "admin")
        #expect(delegate.lastError == nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test
    @MainActor
    func testLoginFailure() async {
        let delegate = MockLoginDelegateNextGen()
        let strategy = MockLoginStrategyNextGen(shouldSucceed: false)
        let viewModel = LoginViewModelNextGen(strategies: [strategy], delegate: delegate)
        viewModel.username = "badusername"
        viewModel.password = "badpassword"
        
        await viewModel.login(using: strategy)
        
        #expect(delegate.lastStatus == .error)
        #expect(delegate.lastUser == nil)
        #expect(delegate.lastError != nil)
        #expect(viewModel.errorMessage == "Invalid credentials")
        #expect(viewModel.isLoading == false)
    }

}
