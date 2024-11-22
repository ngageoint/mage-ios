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
    var loginParameters: [AnyHashable : Any]?;
    var loginCalled = false;
    var authenticationStrategy: String?;
    var changeServerURLCalled = false;
    var createAccountCalled = false;
    
    func login(withParameters parameters: [AnyHashable : Any]!, withAuthenticationStrategy: String, complete: ((AuthenticationStatus, String?) -> Void)!) {
        loginCalled = true;
        loginParameters = parameters;
        self.authenticationStrategy = withAuthenticationStrategy;
    }
    
    func changeServerURL() {
        changeServerURLCalled = true;
    }
    
    func createAccount() {
        createAccountCalled = true;
    }
}

class AuthenticationSuccessMockLoginDelegate: MockLoginDelegate {
    override func login(withParameters parameters: [AnyHashable : Any]!, withAuthenticationStrategy: String, complete: ((AuthenticationStatus, String?) -> Void)!) {
        super.login(withParameters: parameters, withAuthenticationStrategy: withAuthenticationStrategy, complete: nil);
        complete(AuthenticationStatus.AUTHENTICATION_SUCCESS, nil);
    }
}

class RegistrationSuccessMockLoginDelegate: MockLoginDelegate {
    override func login(withParameters parameters: [AnyHashable : Any]!, withAuthenticationStrategy: String, complete: ((AuthenticationStatus, String?) -> Void)!) {
        super.login(withParameters: parameters, withAuthenticationStrategy: withAuthenticationStrategy, complete: nil);
        complete(AuthenticationStatus.REGISTRATION_SUCCESS, nil);
    }
}

class AuthenticationFailMockLoginDelegate: MockLoginDelegate {
    override func login(withParameters parameters: [AnyHashable : Any]!, withAuthenticationStrategy: String, complete: ((AuthenticationStatus, String?) -> Void)!) {
        super.login(withParameters: parameters, withAuthenticationStrategy: withAuthenticationStrategy, complete: nil);
        complete(AuthenticationStatus.UNABLE_TO_AUTHENTICATE, nil);
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
    func testShouldLoadTheProceedToEachFieldInOrder() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let uuidString: String = DeviceUUID.retrieveDeviceUUID()!.uuidString;
        print("XXX uuidString \(uuidString)")
        let appVersion: String = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)-\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)";
        
        let delegate: MockLoginDelegate = MockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In");
        
        tester().enterText("username\n", intoViewWithAccessibilityLabel: "Username");
        tester().waitForFirstResponder(withAccessibilityLabel: "Password");
        tester().enterText("password\n", intoViewWithAccessibilityLabel: "Password");
        
        expect(delegate.loginCalled).toEventually(beTrue());
        
        let expectedLoginParameters: [AnyHashable: Any?] = [
            "username": "username",
            "password": "password",
            "strategy": [
                "passwordMinLength": 14
            ],
            "uid":uuidString,
            "appVersion": appVersion
        ];
        expect(delegate.loginParameters!["username"] as? String).to(equal(expectedLoginParameters["username"] as? String));
        expect(delegate.loginParameters!["password"] as? String).to(equal(expectedLoginParameters["password"] as? String));
        expect(delegate.loginParameters!["uid"] as? String).to(equal(expectedLoginParameters["uid"] as? String));
        expect(delegate.loginParameters!["appVersion"] as? String).to(equal(expectedLoginParameters["appVersion"] as? String));
    }
    
    @MainActor
    func testShouldShowThePassword() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = MockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Show Password");
        let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
        
        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
        
        expect(passwordField.isSecureTextEntry).to(beTrue());
        tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Password");
        
        expect(passwordField.isSecureTextEntry).to(beFalse());
    }
    
    @MainActor
    func testShouldDelegateToCreateAnAccount() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = MockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Sign Up Here");
        tester().tapView(withAccessibilityLabel: "Sign Up Here");
        
        expect(delegate.createAccountCalled).to(beTrue());
    }
    
    @MainActor
    func testShouldFillInUsernameForPassedInUser() {
        MageCoreDataFixtures.addUser();
        MageCoreDataFixtures.addUnsyncedObservationToEvent();
        
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = MockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        localLoginView.user = User.mr_findFirst();
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Sign In");
        
        let usernameField: UITextField = viewTester().usingLabel("Username").view as! UITextField;
        
        expect(usernameField.text).to(equal(User.mr_findFirst()?.username));
        expect(usernameField.isEnabled).to(beFalse());
    }
    
    @MainActor
    func testShouldLogInIfBothFieldsAreFilledIn() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = MockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In");
        
        tester().enterText("password\n", intoViewWithAccessibilityLabel: "Password");
        tester().waitForFirstResponder(withAccessibilityLabel: "Username");
        tester().enterText("username\n", intoViewWithAccessibilityLabel: "Username");
        
        expect(delegate.loginCalled).to(beTrue());
        expect(delegate.loginParameters!["username"] as? String).to(equal("username"));
        expect(delegate.loginParameters!["password"] as? String).to(equal("password"));
    }
    
    @MainActor
    func testShouldResignUsernameAndPasswordFieldsAfterLogin() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = MockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In");
        
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username");
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password");
        
        tester().tapView(withAccessibilityLabel: "Sign In");
        expect(delegate.loginCalled).to(beTrue());
        expect(delegate.loginParameters!["username"] as? String).to(equal("username"));
        expect(delegate.loginParameters!["password"] as? String).to(equal("password"));
        
        let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
        let usernameField: UITextField = viewTester().usingLabel("Username").view as! UITextField;
        expect(passwordField.isFirstResponder).to(beFalse());
        expect(usernameField.isFirstResponder).to(beFalse());
    }
    
    @MainActor
    func testShouldResignUsernameFieldAfterLoginIfUsernameIsEnteredSecond() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = MockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In");
        
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password");
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username");
        
        tester().tapView(withAccessibilityLabel: "Sign In");
        expect(delegate.loginCalled).to(beTrue());
        expect(delegate.loginParameters!["username"] as? String).to(equal("username"));
        expect(delegate.loginParameters!["password"] as? String).to(equal("password"));
        
        let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
        let usernameField: UITextField = viewTester().usingLabel("Username").view as! UITextField;
        expect(passwordField.isFirstResponder).to(beFalse());
        expect(usernameField.isFirstResponder).to(beFalse());
    }
    
    @MainActor
    func testShouldClearTheLoginFieldsAfterSuccess() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = AuthenticationSuccessMockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In");
        
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username");
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password");

        tester().tapView(withAccessibilityLabel: "Sign In");
        expect(delegate.loginCalled).to(beTrue());
        expect(delegate.loginParameters!["username"] as? String).to(equal("username"));
        expect(delegate.loginParameters!["password"] as? String).to(equal("password"));
        
        let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
        let usernameField: UITextField = viewTester().usingLabel("Username").view as! UITextField;

        expect(passwordField.text).to(equal(""));
        expect(usernameField.text).to(equal(""));
    }
    
    @MainActor
    func testShouldNotClearTheLoginFieldsAfterRegistrationSuccess() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = RegistrationSuccessMockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In");
        
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username");
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password");
        
        tester().tapView(withAccessibilityLabel: "Sign In");
        expect(delegate.loginCalled).to(beTrue());
        expect(delegate.loginParameters!["username"] as? String).to(equal("username"));
        expect(delegate.loginParameters!["password"] as? String).to(equal("password"));
        
        let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
        let usernameField: UITextField = viewTester().usingLabel("Username").view as! UITextField;
        
        expect(passwordField.text).to(equal("password"));
        expect(usernameField.text).to(equal("username"));
    }
    
    @MainActor
    func testShouldNotClearTheLoginFieldsAfterAuthenticationFailure() {
        let strategy: [AnyHashable : Any?] = [
            "identifier": "local",
            "strategy": [
                "passwordMinLength":14
            ]
        ]
        
        let delegate: MockLoginDelegate = AuthenticationFailMockLoginDelegate();
        
        localLoginView = LocalLoginView();
        localLoginView.configureForAutoLayout();
        localLoginView.applyTheme(withContainerScheme: MAGEScheme.scheme())
        localLoginView.delegate = delegate;
        localLoginView.strategy = strategy as [AnyHashable : Any];
        
        view.addSubview(localLoginView);
        localLoginView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "Username");
        tester().waitForView(withAccessibilityLabel: "Password");
        tester().waitForView(withAccessibilityLabel: "Sign In");
        
        tester().enterText("username", intoViewWithAccessibilityLabel: "Username");
        tester().enterText("password", intoViewWithAccessibilityLabel: "Password");
        
        tester().tapView(withAccessibilityLabel: "Sign In");
        expect(delegate.loginCalled).to(beTrue());
        expect(delegate.loginParameters!["username"] as? String).to(equal("username"));
        expect(delegate.loginParameters!["password"] as? String).to(equal("password"));
        
        let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
        let usernameField: UITextField = viewTester().usingLabel("Username").view as! UITextField;
        
        expect(passwordField.text).to(equal("password"));
        expect(usernameField.text).to(equal("username"));
    }
}
