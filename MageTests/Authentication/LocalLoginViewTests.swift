//
//  LocalLoginViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/9/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import PureLayout
import Kingfisher
import OHHTTPStubs
import SwiftUI

@testable import MAGE

class MockLoginDelegate: LoginDelegate {
    var loginCalled = false
    var loginParameters: [AnyHashable: Any]?
    var authenticationStrategy: String?
    var changeServerURLCalled = false
    var createAccountCalled = false
    var mockStatus: AuthenticationStatus = .UNABLE_TO_AUTHENTICATE

    init(status: AuthenticationStatus = .UNABLE_TO_AUTHENTICATE) {
        self.mockStatus = status
    }
    
    func login(withParameters parameters: [AnyHashable: Any]!, withAuthenticationStrategy: String, complete: ((AuthenticationStatus, String?) -> Void)!) {
        loginCalled = true
        loginParameters = parameters
        authenticationStrategy = withAuthenticationStrategy
        complete?(mockStatus, nil)
    }

    func changeServerURL() {
        changeServerURLCalled = true
    }

    func createAccount() {
        createAccountCalled = true
    }
}

class LocalLoginViewTests: AsyncMageCoreDataTestCase {
    var window: UIWindow?;
    var view: UIView!;
    var controller: UIViewController?;
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        
        UserDefaults.standard.baseServerUrl = "https://magetest";
                        
        view = UIView(forAutoLayout: ());
        view.autoSetDimension(.width, toSize: 300);
        view.backgroundColor = .white;
        
        controller = UIViewController();
        window = TestHelpers.getKeyWindowVisible();
        window!.rootViewController = controller;
        controller?.view.addSubview(view);
    }
    
    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        window?.rootViewController?.dismiss(animated: false, completion: nil);
        window?.rootViewController = nil;
        controller = nil;
        view = nil;
    }
    
    @MainActor
    private func setupLoginView(with delegate: MockLoginDelegate, user: User? = nil) -> LocalLoginViewModel {
        let viewModel = LocalLoginViewModel(strategy: defaultLoginStrategy(), delegate: delegate)
        
        if let user {
            viewModel.username = user.username ?? ""
        }
        
        let swiftUIView = LocalLoginViewSwiftUI(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        
        controller?.addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: controller!)
        return viewModel
    }
    
    private func defaultLoginStrategy() -> [String: Any] {
        return [
            "identifier": "local",
            "strategy": ["passwordMinLength": 14]
        ]
    }
    
    @MainActor
    func testShouldLoadTheLocalLoginView() {
        let delegate = MockLoginDelegate()
        let viewModel = LocalLoginViewModel(strategy: defaultLoginStrategy(), delegate: delegate)
        let swiftUIView = LocalLoginViewSwiftUI(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: swiftUIView)
        
        controller?.addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: controller)
        tester().waitForView(withAccessibilityIdentifier: "Local Login View")
        tester().waitForView(withAccessibilityLabel: "Username")
        tester().waitForView(withAccessibilityLabel: "Password")
        tester().waitForView(withAccessibilityLabel: "Sign In")
    }
    
//    @MainActor
//    func testShouldShowThePassword() {
//        let delegate = MockLoginDelegate()
//
//        setupLoginView(with: delegate)
//        tester().waitForView(withAccessibilityLabel: "Show Password")
//        let passwordField = viewTester().usingLabel("Password").view as! UITextField
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password")
//        XCTAssertTrue(passwordField.isSecureTextEntry, "Password should be hidden initially")
//        tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Password")
//        XCTAssertFalse(passwordField.isSecureTextEntry, "Password should be visible after toggling the switch")
//    }
    
//    @MainActor
//    func testShouldDelegateToCreateAnAccount() {
//        let delegate = MockLoginDelegate()
//        setupLoginView(with: delegate)
//        tester().waitForView(withAccessibilityLabel: "Sign Up Here")
//        tester().tapView(withAccessibilityLabel: "Sign Up Here")
//        XCTAssertTrue(delegate.createAccountCalled)
//    }
    
//    @MainActor
//    func testShouldFillInUsernameForPassedInUser() {
//        MageCoreDataFixtures.addUser();
//        MageCoreDataFixtures.addUnsyncedObservationToEvent();
//        
//        guard let user = User.mr_findFirst() else {
//            XCTFail("Expected a user to be present, but found nil")
//            return
//        }
//
//        let delegate = MockLoginDelegate()
//
//        setupLoginView(with: delegate, user: user)
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        
//        let usernameField: UITextField = viewTester().usingLabel("Username").view as! UITextField;
//        
//        XCTAssertEqual(usernameField.text, user.username)
//        XCTAssertFalse(usernameField.isEnabled)
//    }
    
//    @MainActor
//    func testShouldLogInIfBothFieldsAreFilledIn() {
//        let expectation = XCTestExpectation(description: "Login should be called")
//        let delegate = MockLoginDelegate()
//        
//        setupLoginView(with: delegate)
//        
//        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
//        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")
//        tester().tapView(withAccessibilityLabel: "Sign In")
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            XCTAssertTrue(delegate.loginCalled)
//            XCTAssertEqual(delegate.loginParameters!["username"] as? String, "username")
//            XCTAssertEqual(delegate.loginParameters!["password"] as? String, "password")
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 2.0)
//    }
    
//    @MainActor
//    func testShouldResignUsernameAndPasswordFieldsAfterLogin() {
//        let delegate = MockLoginDelegate(status: .AUTHENTICATION_SUCCESS)
//
//        setupLoginView(with: delegate)
//
//        tester().waitForView(withAccessibilityLabel: "Username")
//        tester().waitForView(withAccessibilityLabel: "Password")
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
//        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")
//
//        let loginExpectation = expectation(description: "Login should be called")
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
//            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
//            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
//            loginExpectation.fulfill()
//        }
//
//        tester().tapView(withAccessibilityLabel: "Sign In")
//        wait(for: [loginExpectation], timeout: 2.0)
//
//        let passwordField = viewTester().usingLabel("Password").view as! UITextField
//        let usernameField = viewTester().usingLabel("Username").view as! UITextField
//
//        XCTAssertFalse(passwordField.isFirstResponder, "Password field should no longer be the first responder")
//        XCTAssertFalse(usernameField.isFirstResponder, "Username field should no longer be the first responder")
//    }

//    @MainActor
//    func testShouldResignUsernameFieldAfterLoginIfUsernameIsEnteredSecond() {
//        let delegate = MockLoginDelegate(status: .AUTHENTICATION_SUCCESS)
//
//        setupLoginView(with: delegate)
//
//        tester().waitForView(withAccessibilityLabel: "Username")
//        tester().waitForView(withAccessibilityLabel: "Password")
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")
//        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
//        tester().waitForFirstResponder(withAccessibilityLabel: "Username")
//
//        let loginExpectation = expectation(description: "Login should be called")
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
//            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
//            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
//            loginExpectation.fulfill()
//        }
//
//        tester().tapView(withAccessibilityLabel: "Sign In")
//        wait(for: [loginExpectation], timeout: 2.0)
//
//        let passwordField = viewTester().usingLabel("Password").view as! UITextField
//        let usernameField = viewTester().usingLabel("Username").view as! UITextField
//
//        XCTAssertFalse(passwordField.isFirstResponder, "Password field should no longer be the first responder")
//        XCTAssertFalse(usernameField.isFirstResponder, "Username field should no longer be the first responder")
//    }
    
//    @MainActor
//    func testShouldClearTheLoginFieldsAfterSuccess() {
//        let delegate = MockLoginDelegate(status: .AUTHENTICATION_SUCCESS)
//
//        setupLoginView(with: delegate)
//
//        tester().waitForView(withAccessibilityLabel: "Username")
//        tester().waitForView(withAccessibilityLabel: "Password")
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
//        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")
//
//        let loginExpectation = expectation(description: "Login should be called")
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
//            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
//            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
//            loginExpectation.fulfill()
//        }
//
//        tester().tapView(withAccessibilityLabel: "Sign In")
//        wait(for: [loginExpectation], timeout: 2.0)
//
//        let passwordField = viewTester().usingLabel("Password").view as! UITextField
//        let usernameField = viewTester().usingLabel("Username").view as! UITextField
//
//        XCTAssertEqual(passwordField.text, "", "Password field should be cleared after successful login")
//        XCTAssertEqual(usernameField.text, "", "Username field should be cleared after successful login")
//    }
//
//    @MainActor
//    func testShouldNotClearTheLoginFieldsAfterRegistrationSuccess() {
//        let delegate = MockLoginDelegate(status: .REGISTRATION_SUCCESS)
//
//        setupLoginView(with: delegate)
//
//        tester().waitForView(withAccessibilityLabel: "Username")
//        tester().waitForView(withAccessibilityLabel: "Password")
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
//        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")
//
//        let loginExpectation = expectation(description: "Login should be called")
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
//            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
//            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
//            loginExpectation.fulfill()
//        }
//
//        tester().tapView(withAccessibilityLabel: "Sign In")
//        wait(for: [loginExpectation], timeout: 2.0)
//
//        let passwordField = viewTester().usingLabel("Password").view as! UITextField
//        let usernameField = viewTester().usingLabel("Username").view as! UITextField
//
//        XCTAssertEqual(passwordField.text, "password", "Password field should retain value after registration success")
//        XCTAssertEqual(usernameField.text, "username", "Username field should retain value after registration success")
//    }
//
//    @MainActor
//    func testShouldNotClearTheLoginFieldsAfterAuthenticationFailure() {
//        let delegate = MockLoginDelegate(status: .UNABLE_TO_AUTHENTICATE)
//
//        setupLoginView(with: delegate)
//
//        tester().waitForView(withAccessibilityLabel: "Username")
//        tester().waitForView(withAccessibilityLabel: "Password")
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
//        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")
//
//        let loginExpectation = expectation(description: "Login attempt should fail")
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
//            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
//            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
//            loginExpectation.fulfill()
//        }
//
//        tester().tapView(withAccessibilityLabel: "Sign In")
//        wait(for: [loginExpectation], timeout: 2.0)
//
//        let passwordField = viewTester().usingLabel("Password").view as! UITextField
//        let usernameField = viewTester().usingLabel("Username").view as! UITextField
//
//        XCTAssertEqual(passwordField.text, "password", "Password field should retain value after failed login")
//        XCTAssertEqual(usernameField.text, "username", "Username field should retain value after failed login")
//    }
}
