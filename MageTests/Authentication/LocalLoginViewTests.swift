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

@testable import MAGE

class MockLoginDelegate: LoginDelegate {
    var loginCalled = false
    var loginParameters: [AnyHashable: Any]?
    var authenticationStrategy: String?
    var changeServerURLCalled = false
    var createAccountCalled = false
    var mockStatus: AuthenticationStatus = .UNABLE_TO_AUTHENTICATE // Default failure

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
    var localLoginView: LocalLoginView!;
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
    
    private func defaultLoginStrategy() -> [AnyHashable: Any] {
        return [
            "identifier": "local",
            "strategy": ["passwordMinLength": 14]
        ]
    }
    
    @MainActor
    func testShouldLoadTheLocaLoginViewAsANib() {
        localLoginView = UINib(nibName: "local-authView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? LocalLoginView;
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        tester().waitForView(withAccessibilityLabel: "Local Login View");
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In")
    }
    
    @MainActor
    func testShouldLoadTheLocalLoginView() {
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Local Login View");
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In")
    }
    
    @MainActor
    private func setupLoginView(with delegate: MockLoginDelegate, user: User? = nil) {
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate
        localLoginView.strategy = defaultLoginStrategy()

        // ✅ If a user is passed, assign it to the view
         if let user = user {
             localLoginView.user = user
         }

        view.addSubview(localLoginView)
        localLoginView.autoPinEdgesToSuperviewEdges()
    }
    
    @MainActor
    func testShouldLoadTheProceedToEachFieldInOrder() {
        // ✅ Retrieve UUID and appVersion once
        guard let uuidString = DeviceUUID.retrieveDeviceUUID()?.uuidString else {
            XCTFail("UUID should not be nil")
            return
        }
        
        let appVersion = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)-\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)"

        let delegate = MockLoginDelegate()
        
        // ✅ Use helper function to set up the login view
        setupLoginView(with: delegate)

        // ✅ Ensure fields exist
        tester().waitForView(withAccessibilityLabel: "Username")
        tester().waitForView(withAccessibilityLabel: "Password")
        tester().waitForView(withAccessibilityLabel: "Sign In")

        // ✅ Simulate user entering username and pressing "Next"
        tester().enterText("username\n", intoViewWithAccessibilityLabel: "Username")
        tester().waitForFirstResponder(withAccessibilityLabel: "Password")  // Verify focus shifts to Password
        
        // ✅ Simulate entering password and pressing "Next"
        tester().enterText("password\n", intoViewWithAccessibilityLabel: "Password")

        // ✅ Use XCTExpectation instead of `expect(...).toEventually(...)`
        let loginExpectation = expectation(description: "Login delegate should be called")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
            loginExpectation.fulfill()
        }
        
        wait(for: [loginExpectation], timeout: 2.0)

        // ✅ Verify login parameters
        XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
        XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
        XCTAssertEqual(delegate.loginParameters?["uid"] as? String, uuidString)
        XCTAssertEqual(delegate.loginParameters?["appVersion"] as? String, appVersion)
    }

    @MainActor
    func testShouldShowThePassword() {
        let delegate = MockLoginDelegate()

        // ✅ Use helper function to set up the login view
        setupLoginView(with: delegate)

        // ✅ Ensure "Show Password" switch is visible
        tester().waitForView(withAccessibilityLabel: "Show Password")

        // ✅ Get the password field
        let passwordField = viewTester().usingLabel("Password").view as! UITextField

        // ✅ Enter password and verify it's hidden initially
        tester().setText("password", intoViewWithAccessibilityLabel: "Password")
        XCTAssertTrue(passwordField.isSecureTextEntry, "Password should be hidden initially")

        // ✅ Toggle "Show Password" switch
        tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Password")

        // ✅ Verify the password is now visible
        XCTAssertFalse(passwordField.isSecureTextEntry, "Password should be visible after toggling the switch")
    }
    
    @MainActor
    func testShouldDelegateToCreateAnAccount() {
        let delegate = MockLoginDelegate()

        // ✅ Use helper function to set up the login view
        setupLoginView(with: delegate)

        // ✅ Ensure "Sign Up Here" button is present
        tester().waitForView(withAccessibilityLabel: "Sign Up Here")

        // ✅ Tap the "Sign Up Here" button
        tester().tapView(withAccessibilityLabel: "Sign Up Here")

        // ✅ Verify that the delegate was called
        XCTAssertTrue(delegate.createAccountCalled)
    }
    
    @MainActor
    func testShouldFillInUsernameForPassedInUser() {
        MageCoreDataFixtures.addUser();
        MageCoreDataFixtures.addUnsyncedObservationToEvent();
        
        // ✅ Fetch user once instead of calling `User.mr_findFirst()` multiple times
        guard let user = User.mr_findFirst() else {
            XCTFail("Expected a user to be present, but found nil")
            return
        }

        let delegate = MockLoginDelegate()

        // ✅ Use helper function for setup
        setupLoginView(with: delegate, user: user)
        
        // ✅ Ensure the UI is properly loaded
        tester().waitForView(withAccessibilityLabel: "Sign In")
        
        // ✅ Get the username field
        let usernameField: UITextField = viewTester().usingLabel("Username").view as! UITextField;
        
        // ✅ Verify the username is pre-filled and field is disabled
        XCTAssertEqual(usernameField.text, user.username)
        XCTAssertFalse(usernameField.isEnabled)
    }
    
    @MainActor
    func testShouldLogInIfBothFieldsAreFilledIn() {
        let expectation = XCTestExpectation(description: "Login should be called")
        let delegate = MockLoginDelegate()
        
        setupLoginView(with: delegate)
        
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")
        tester().tapView(withAccessibilityLabel: "Sign In")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(delegate.loginCalled)
            XCTAssertEqual(delegate.loginParameters!["username"] as? String, "username")
            XCTAssertEqual(delegate.loginParameters!["password"] as? String, "password")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    @MainActor
    func testShouldResignUsernameAndPasswordFieldsAfterLogin() {
        let delegate = MockLoginDelegate(status: .AUTHENTICATION_SUCCESS)

        // ✅ Use helper function to set up the login view
        setupLoginView(with: delegate)

        // ✅ Ensure UI elements exist
        tester().waitForView(withAccessibilityLabel: "Username")
        tester().waitForView(withAccessibilityLabel: "Password")
        tester().waitForView(withAccessibilityLabel: "Sign In")

        // ✅ Enter credentials
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")

        // ✅ Create expectation for login completion
        let loginExpectation = expectation(description: "Login should be called")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
            loginExpectation.fulfill()
        }

        tester().tapView(withAccessibilityLabel: "Sign In")
        wait(for: [loginExpectation], timeout: 2.0)

        // ✅ Ensure both fields have resigned first responder status
        let passwordField = viewTester().usingLabel("Password").view as! UITextField
        let usernameField = viewTester().usingLabel("Username").view as! UITextField

        XCTAssertFalse(passwordField.isFirstResponder, "Password field should no longer be the first responder")
        XCTAssertFalse(usernameField.isFirstResponder, "Username field should no longer be the first responder")
    }

    @MainActor
    func testShouldResignUsernameFieldAfterLoginIfUsernameIsEnteredSecond() {
        let delegate = MockLoginDelegate(status: .AUTHENTICATION_SUCCESS)

        // ✅ Use helper function to set up the login view
        setupLoginView(with: delegate)

        // ✅ Ensure UI elements exist
        tester().waitForView(withAccessibilityLabel: "Username")
        tester().waitForView(withAccessibilityLabel: "Password")
        tester().waitForView(withAccessibilityLabel: "Sign In")

        // ✅ Enter password first, then username
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")

        // ✅ Ensure username field becomes first responder before login
        tester().waitForFirstResponder(withAccessibilityLabel: "Username")

        // ✅ Create expectation for login completion
        let loginExpectation = expectation(description: "Login should be called")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
            loginExpectation.fulfill()
        }

        tester().tapView(withAccessibilityLabel: "Sign In")
        wait(for: [loginExpectation], timeout: 2.0)

        // ✅ Ensure both fields have resigned first responder status
        let passwordField = viewTester().usingLabel("Password").view as! UITextField
        let usernameField = viewTester().usingLabel("Username").view as! UITextField

        XCTAssertFalse(passwordField.isFirstResponder, "Password field should no longer be the first responder")
        XCTAssertFalse(usernameField.isFirstResponder, "Username field should no longer be the first responder")
    }
    
    @MainActor
    func testShouldClearTheLoginFieldsAfterSuccess() {
        let delegate = MockLoginDelegate(status: .AUTHENTICATION_SUCCESS)

        // ✅ Use helper function to set up the login view
        setupLoginView(with: delegate)

        // ✅ Ensure UI elements exist
        tester().waitForView(withAccessibilityLabel: "Username")
        tester().waitForView(withAccessibilityLabel: "Password")
        tester().waitForView(withAccessibilityLabel: "Sign In")

        // ✅ Enter credentials
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")

        // ✅ Create expectation for login completion
        let loginExpectation = expectation(description: "Login should be called")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
            loginExpectation.fulfill()
        }

        tester().tapView(withAccessibilityLabel: "Sign In")
        wait(for: [loginExpectation], timeout: 2.0)

        // ✅ Ensure fields are cleared after login success
        let passwordField = viewTester().usingLabel("Password").view as! UITextField
        let usernameField = viewTester().usingLabel("Username").view as! UITextField

        XCTAssertEqual(passwordField.text, "", "Password field should be cleared after successful login")
        XCTAssertEqual(usernameField.text, "", "Username field should be cleared after successful login")
    }

    @MainActor
    func testShouldNotClearTheLoginFieldsAfterRegistrationSuccess() {
        let delegate = MockLoginDelegate(status: .REGISTRATION_SUCCESS)

        // ✅ Use helper function to set up the login view
        setupLoginView(with: delegate)

        // ✅ Ensure UI elements exist
        tester().waitForView(withAccessibilityLabel: "Username")
        tester().waitForView(withAccessibilityLabel: "Password")
        tester().waitForView(withAccessibilityLabel: "Sign In")

        // ✅ Enter credentials
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")

        // ✅ Create expectation for login completion
        let loginExpectation = expectation(description: "Login should be called")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
            loginExpectation.fulfill()
        }

        tester().tapView(withAccessibilityLabel: "Sign In")
        wait(for: [loginExpectation], timeout: 2.0)

        // ✅ Ensure fields are NOT cleared after registration success
        let passwordField = viewTester().usingLabel("Password").view as! UITextField
        let usernameField = viewTester().usingLabel("Username").view as! UITextField

        XCTAssertEqual(passwordField.text, "password", "Password field should retain value after registration success")
        XCTAssertEqual(usernameField.text, "username", "Username field should retain value after registration success")
    }

    @MainActor
    func testShouldNotClearTheLoginFieldsAfterAuthenticationFailure() {
        let delegate = MockLoginDelegate(status: .UNABLE_TO_AUTHENTICATE)

        // ✅ Use helper function to set up the login view
        setupLoginView(with: delegate)

        // ✅ Ensure UI elements exist
        tester().waitForView(withAccessibilityLabel: "Username")
        tester().waitForView(withAccessibilityLabel: "Password")
        tester().waitForView(withAccessibilityLabel: "Sign In")

        // ✅ Enter credentials
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username")
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password")

        // ✅ Create expectation for failed login attempt
        let loginExpectation = expectation(description: "Login attempt should fail")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(delegate.loginCalled, "Login should be triggered")
            XCTAssertEqual(delegate.loginParameters?["username"] as? String, "username")
            XCTAssertEqual(delegate.loginParameters?["password"] as? String, "password")
            loginExpectation.fulfill()
        }

        tester().tapView(withAccessibilityLabel: "Sign In")
        wait(for: [loginExpectation], timeout: 2.0)

        // ✅ Ensure fields are NOT cleared after login failure
        let passwordField = viewTester().usingLabel("Password").view as! UITextField
        let usernameField = viewTester().usingLabel("Username").view as! UITextField

        XCTAssertEqual(passwordField.text, "password", "Password field should retain value after failed login")
        XCTAssertEqual(usernameField.text, "username", "Username field should retain value after failed login")
    }
}
