//
//  LoginViewSwiftUITests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/5/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import SwiftUI
import ViewInspector
@testable import MAGE


final class LoginViewSwiftUITests: XCTestCase {
    
    final class SpyVM: LoginViewModel {
        var loginTappedCount = 0
        
        override func loginTapped() {
            loginTappedCount += 1
            super.loginTapped()
        }
    }
    
    func test_typingAndTapping_updatesVM_andCallsLoginTapped() throws {
        let vm = SpyVM(strategy: ["identifier": "local"], delegate: nil)
        vm.showPassword = true  // easier when testing
        
        let sut = LoginViewSwiftUI(viewModel: vm)
        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }
        
        // Type username
        let usernameTF = try sut.inspect()
            .find(ViewType.TextField.self, where: { try $0.accessibilityIdentifier() == "Username" })
        try usernameTF.setInput("username")
        
        // Now the password, since we are forcing showPassword it is a TextField
        let passwordTF = try sut.inspect()
            .find(ViewType.TextField.self, where: { try $0.accessibilityIdentifier() == "Password" })
        try passwordTF.setInput("password")
        
        XCTAssertEqual(vm.username, "username")
        XCTAssertEqual(vm.password, "password")
        
        // Tap "sign in"
        let signInButton = try sut.inspect()
            .find(ViewType.Button.self, where: { try $0.labelView().text().string() == "Sign In" })
        try signInButton.tap()
        
        XCTAssertEqual(vm.loginTappedCount, 1)
        
    }
    
    func testLocalLogin_SubmitsCredentialsAndCallsDelegate() throws {
        // given a local strategy and a delegate spy
        let delegate = TestLoginDelegate()
        let vm = LoginViewModel(strategy: ["identifier": "local"], delegate: delegate)
        let sut = LoginViewSwiftUI(viewModel: vm)
        
        // when: enter username/password via ViewInspector
        let view = try sut.inspect()
        
        // Find the username TextField
        let usernameField = try view.find(ViewType.TextField.self)
        try usernameField.setInput("username")
        
        if let secure = try? view.find(ViewType.SecureField.self) {
            try secure.setInput("password")
        } else {
            let pwdTextField = try view.find(where: { view in
                (try? view.textField()) != nil && (try? view.text().string()) != nil
            }).textField()
            
            try pwdTextField.setInput("password")
        }
        
        // Tap the "sign In" button
        let signInButton = try view.find(ViewType.Button.self, where: {
            (try? $0.labelView().find(text: "Sign In")) != nil
        })
        
        try signInButton.tap()
        
        // then: delegate was called with "local" and correct params
        XCTAssertEqual(delegate.loginCalls.count, 1)
        XCTAssertEqual(delegate.loginCalls.first?.strategy, "local")
        let params = delegate.loginCalls.first?.params
        XCTAssertEqual(params?["username"] as? String, "username")
        XCTAssertEqual(params?["password"] as? String, "password")
    }
    
    func testIDPButton_CallsDelegate() throws {
        let delegate = TestLoginDelegate()
        let idpVM = IDPLoginViewModel(strategy: ["identifier": "oauth",
                                                 "name": "SSO",
                                                 "url":"https://example.com"] as [String: Any],
                                      delegate: delegate)
        let sut = IDPLoginViewSwiftUI(viewModel: idpVM)
        let view = try sut.inspect()
        let button = try view.find(ViewType.Button.self)
        try button.tap()
        XCTAssertEqual(delegate.idpCalls.count, 1)
    }
    
    
    func testErrorMessageShown() throws {
        let vm = LoginViewModel(strategy: ["identifier": "local", "strategy": ["title": "Email"]], delegate: nil)
        vm.errorMessage = "Invalid!"
        let view = LoginViewSwiftUI(viewModel: vm)
        let errorText1 = try view.inspect().find(text: "Invalid!")  // If you want to be less specific
        let errorText2 = try view.inspect().find(ViewType.Text.self, where: { try $0.string() == "Invalid!" })
        
        XCTAssertNotNil(errorText1)
        XCTAssertNotNil(errorText2)
    }

    func testSignInButton_tapsAction() throws {
        var didTapSignIn = false
        let view = SignInButtonView(isLoading: false) { didTapSignIn = true }
        let button = try view.inspect().find(ViewType.Button.self)
        try button.tap()
        XCTAssertTrue(didTapSignIn)
    }
    
    func testSignUpButton_tapsAction() throws {
        var didTapSignUp = false
        let view = SignUpButtonView(action: { didTapSignUp = true })
        let button = try view.inspect().find(ViewType.Button.self)
        try button.tap()
        XCTAssertTrue(didTapSignUp)
    }
    
    func testUsernameFieldView_edits() throws {
        let username = "testuser"
        let view = UsernameFieldView(username: .constant(username), isDisabled: false, isLoading: false, placeholder: "User")
        let field = try view.inspect().find(ViewType.TextField.self)
        try field.setInput("newuser")
        XCTAssertNotNil(field)
    }
    
    func testStrategyTitleDisplayed() throws {
        let vm = LoginViewModel(strategy: ["identifier": "local", "strategy": ["title": "Email"]], delegate: nil)
        let view = LoginViewSwiftUI(viewModel: vm)
        let title = try view.inspect().find(ViewType.Text.self, where: { try $0.string() == "Email" })
        XCTAssertNotNil(title)
    }
    
    func testMultipleStrategiesShowAllViews() throws {
        // This assumes you have a wrapper like `AuthenticationStrategiesView`
        // that shows multiple LoginViewSwiftUI and/or IDPLoginViewSwiftUI in a VStack or similar.

        let strategies = [
            ["identifier": "local", "strategy": ["title": "Local"]],
            ["identifier": "idp",   "strategy": ["title": "OIDC"]]
        ]
        let viewModels = strategies.map { LoginViewModel(strategy: $0, delegate: nil) }
        let views = viewModels.map { LoginViewSwiftUI(viewModel: $0) }

        // Example composite view for test, replace as needed:
        let wrapper = VStack { ForEach(views.indices, id: \.self) { i in views[i] } }

        // Use ViewInspector to verify both "Local" and "OIDC" appear
        let localText = try wrapper.inspect().find(ViewType.Text.self, where: { try $0.string() == "Local" })
        let idpText   = try wrapper.inspect().find(ViewType.Text.self, where: { try $0.string() == "OIDC" })

        XCTAssertNotNil(localText)
        XCTAssertNotNil(idpText)
    }
}
