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

@available(iOS 13.0, *)

class MockLoginDelegate: LoginDelegate {
    var loginParameters: [AnyHashable : Any]?;
    var loginCalled = false;
    var authenticationType: AuthenticationType?;
    var changeServerURLCalled = false;
    var createAccountCalled = false;
    
    func login(withParameters parameters: [AnyHashable : Any]!, with authenticationType: AuthenticationType, complete: ((AuthenticationStatus, String?) -> Void)!) {
        loginCalled = true;
        loginParameters = parameters;
        self.authenticationType = authenticationType;
    }
    
    func changeServerURL() {
        changeServerURLCalled = true;
    }
    
    func createAccount() {
        createAccountCalled = true;
    }
}

class AuthenticationSuccessMockLoginDelegate: MockLoginDelegate {
    override func login(withParameters parameters: [AnyHashable : Any]!, with authenticationType: AuthenticationType, complete: ((AuthenticationStatus, String?) -> Void)!) {
        super.login(withParameters: parameters, with: authenticationType, complete: nil);
        complete(AuthenticationStatus.AUTHENTICATION_SUCCESS, nil);
    }
}

class RegistrationSuccessMockLoginDelegate: MockLoginDelegate {
    override func login(withParameters parameters: [AnyHashable : Any]!, with authenticationType: AuthenticationType, complete: ((AuthenticationStatus, String?) -> Void)!) {
        super.login(withParameters: parameters, with: authenticationType, complete: nil);
        complete(AuthenticationStatus.REGISTRATION_SUCCESS, nil);
    }
}

class AuthenticationFailMockLoginDelegate: MockLoginDelegate {
    override func login(withParameters parameters: [AnyHashable : Any]!, with authenticationType: AuthenticationType, complete: ((AuthenticationStatus, String?) -> Void)!) {
        super.login(withParameters: parameters, with: authenticationType, complete: nil);
        complete(AuthenticationStatus.UNABLE_TO_AUTHENTICATE, nil);
    }
}

class LocalLoginViewTests: KIFSpec {
    
    override func spec() {
        
        describe("LocalLoginViewTests") {
            
            var window: UIWindow?;
            var view: UIView!;
            var localLoginView: LocalLoginView!;
            var controller: ContainingUIViewController?;
            var delegate: MockLoginDelegate!;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                window = UIWindow(forAutoLayout: ());
                window?.autoSetDimension(.width, toSize: 414);
                window?.makeKeyAndVisible();
                
                UserDefaults.MageServerDefaults.set("https://magetest", forKey: .baseServerUrl);
                                
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .white;
                
                controller = ContainingUIViewController();
                window?.rootViewController = controller;
                controller?.view.addSubview(view);
                
                delegate = MockLoginDelegate();
            }
            
            afterEach {
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                controller = nil;
                view = nil;
                window?.resignKey();
                window = nil;
                TestHelpers.clearAndSetUpStack();
                tester().waitForAnimationsToFinish();
                HTTPStubs.removeAllStubs();
            }
            
            it("should load the Local Login View as a nib") {
                localLoginView = UINib(nibName: "local-authView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as! LocalLoginView;
                view.addSubview(localLoginView);
                localLoginView?.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "Local Login View");
                tester().waitForView(withAccessibilityLabel: "Username");
                tester().waitForView(withAccessibilityLabel: "Password");
                tester().waitForView(withAccessibilityLabel: "Sign In")
            }
            
            it("should load the Local Login View") {
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
                view.addSubview(localLoginView);
                localLoginView?.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "Local Login View");
                tester().waitForView(withAccessibilityLabel: "Username");
                tester().waitForView(withAccessibilityLabel: "Password");
                tester().waitForView(withAccessibilityLabel: "Sign In")
            }
            
            it("should load the proceed to each field in order") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let uuidString: String = DeviceUUID.retrieveDeviceUUID()!.uuidString;
                let appVersion: String = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)-\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)";
                
                let delegate: MockLoginDelegate = MockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
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
            
            it("should show the password") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = MockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
                localLoginView.delegate = delegate;
                localLoginView.strategy = strategy as [AnyHashable : Any];
                
                view.addSubview(localLoginView);
                localLoginView?.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "Show Password");
                let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
                
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                expect(passwordField.isSecureTextEntry).to(beTrue());
                tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Password");
                tester().waitForAnimationsToFinish();
                
                expect(passwordField.isSecureTextEntry).to(beFalse());
            }
            
            it("should delegate to create an account") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = MockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
                localLoginView.delegate = delegate;
                localLoginView.strategy = strategy as [AnyHashable : Any];
                
                view.addSubview(localLoginView);
                localLoginView?.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "Sign Up Here");
                tester().tapView(withAccessibilityLabel: "Sign Up Here");
                
                expect(delegate.createAccountCalled).to(beTrue());
            }
            
            it("should fill in username for passed in user") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        MageCoreDataFixtures.addUnsyncedObservationToEvent { (_, _) in
                            done();
                        }
                    }
                }
                
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = MockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
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
            
            it("should log in if both fields are filled in") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = MockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
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
            
            it("should resign username and password fields after login") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = MockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
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
            
            it("should resign username field after login if username is entered second") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = MockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
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
            
            it("should clear the login fields after success") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = AuthenticationSuccessMockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
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
            
            it("should not clear the login fields after registration success") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = RegistrationSuccessMockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
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
            
            it("should not clear the login fields after authentication failure") {
                let strategy: [AnyHashable : Any?] = [
                    "identifier": "local",
                    "strategy": [
                        "passwordMinLength":14
                    ]
                ]
                
                let delegate: MockLoginDelegate = AuthenticationFailMockLoginDelegate();
                
                localLoginView = LocalLoginView();
                localLoginView.configureForAutoLayout();
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
    }
}
