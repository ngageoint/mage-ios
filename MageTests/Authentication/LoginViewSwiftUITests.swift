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
