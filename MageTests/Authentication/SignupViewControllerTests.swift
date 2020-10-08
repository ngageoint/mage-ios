//
//  SignupViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/7/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import PureLayout
import OHHTTPStubs
import Kingfisher
import MagicalRecord

@testable import MAGE

@available(iOS 13.0, *)

class MockSignUpDelegate: NSObject, SignUpDelegate {
    var signupParameters: [AnyHashable : Any]?;
    var url: URL?;
    var signUpCalled = false;
    var signupCanceledCalled = false;
    
    func signUp(withParameters parameters: [AnyHashable : Any]!, at url: URL!) {
        signUpCalled = true;
        signupParameters = parameters;
    }
    
    func signUpCanceled() {
        signupCanceledCalled = true;
    }
}
//
//class Delegate: MockMageServerDelegate {
//    var urls: [URL?] = [];
//
//    func urlCalled(_ url: URL?, method: String?) {
//        urls.append(url);
//    }
//}

class SignUpViewControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("SignUpViewControllerTests") {
            
            var window: UIWindow?;
            var view: SignUpViewController?;
            var delegate: MockSignUpDelegate?;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                window = UIWindow(forAutoLayout: ());
                window?.autoSetDimension(.width, toSize: 414);
                window?.autoSetDimension(.height, toSize: 896);
                
                UserDefaults.MageServerDefaults.set("https://magetest", forKey: .baseServerUrl);
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent { (_, _) in
                        done();
                    }
                }
                
                Server.setCurrentEventId(1);
                
                delegate = MockSignUpDelegate();
                navigationController = UINavigationController();
                window?.rootViewController = navigationController;
                window?.makeKeyAndVisible();
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                navigationController = nil;
                view = nil;
                delegate = nil;
                window?.resignKey();
                window = nil;
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
                tester().waitForAnimationsToFinish();
            }
            
            it("should load the SignUpViewController") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")), timeout: 10, pollInterval: 1, description: "API request did not happened")
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(SignUpViewController.self));
                expect(viewTester().usingLabel("Username")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Display Name")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Email")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Phone")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Password Confirm")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Cancel")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Sign Up")?.view).toEventuallyNot(beNil());
                tester().waitForView(withAccessibilityLabel: "Version");
                let versionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String;
                tester().expect(viewTester().usingLabel("Version").view, toContainText: "v\(versionString)");
                tester().expect(viewTester().usingLabel("Server URL").view, toContainText: "https://magetest");
            }
            
            it("should not allow signup without required fields") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);

                tester().waitForView(withAccessibilityLabel: "Sign Up");
                tester().tapView(withAccessibilityLabel: "Sign Up");
                
                tester().waitForTappableView(withAccessibilityLabel: "Missing Required Fields");
                let alert: UIAlertController = (navigationController?.presentedViewController as! UIAlertController);
                expect(alert.title).to(equal("Missing Required Fields"));
                expect(alert.message).to(contain("Password"));
                expect(alert.message).to(contain("Password Confirm"));
                expect(alert.message).to(contain("Username"));
                expect(alert.message).to(contain("Display Name"));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should not allow signup with passwords that do not match") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Sign Up");
                
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("passwordsthatdonotmatch", intoViewWithAccessibilityLabel: "Password Confirm");
                
                tester().tapView(withAccessibilityLabel: "Sign Up");
                
                tester().waitForTappableView(withAccessibilityLabel: "Passwords Do Not Match");
                let alert: UIAlertController = (navigationController?.presentedViewController as! UIAlertController);
                expect(alert.title).to(equal("Passwords Do Not Match"));
                expect(alert.message).to(contain("Please update password fields to match."));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should signup") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Sign Up");
                
                tester().enterText("username", intoViewWithAccessibilityLabel: "Username");
                tester().enterText("display", intoViewWithAccessibilityLabel: "Display Name");
                tester().enterText("password", intoViewWithAccessibilityLabel: "Password");
                tester().enterText("password", intoViewWithAccessibilityLabel: "Password Confirm");
                tester().enterText("5555555555", intoViewWithAccessibilityLabel: "Phone", traits: .none, expectedResult: "(555) 555-5555");
                tester().enterText("email@email.com", intoViewWithAccessibilityLabel: "Email");
                
                tester().tapView(withAccessibilityLabel: "Sign Up");
                
                expect(delegate?.signUpCalled).toEventually(beTrue());
                expect(delegate?.signupParameters as! [String: String]).toEventually(equal([
                    "username": "username",
                    "password": "password",
                    "passwordconfirm": "password",
                    "phone": "(555) 555-5555",
                    "email": "email@email.com",
                    "displayName": "display"
                ]))
            }
            
            it("should cancel") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                expect(delegate?.signupCanceledCalled).toEventually(beTrue());
            }
            
            it("should show the password") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Show Password");
                let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
                let passwordConfirmField: UITextField = viewTester().usingLabel("Password Confirm").view as! UITextField;

                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password Confirm");
                
                expect(passwordField.isSecureTextEntry).to(beTrue());
                expect(passwordConfirmField.isSecureTextEntry).to(beTrue());
                tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Password");
                tester().waitForAnimationsToFinish();
                
                expect(passwordField.isSecureTextEntry).to(beFalse());
                expect(passwordConfirmField.isSecureTextEntry).to(beFalse());
            }
            
            it("should update the password strength meter") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Password");
                
                tester().enterText("turtle", intoViewWithAccessibilityLabel: "Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Weak");
                
                tester().clearTextFromView(withAccessibilityLabel: "Password");
                tester().enterText("Turt", intoViewWithAccessibilityLabel: "Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Fair");
                
                tester().clearTextFromView(withAccessibilityLabel: "Password");
                tester().enterText("Turt3", intoViewWithAccessibilityLabel: "Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Good");
                
                tester().clearTextFromView(withAccessibilityLabel: "Password");
                tester().enterText("Turt3!", intoViewWithAccessibilityLabel: "Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Strong");
                
                tester().clearTextFromView(withAccessibilityLabel: "Password");
                tester().enterText("Turt3!@@", intoViewWithAccessibilityLabel: "Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Excellent");
            }
            
            it("should update the phone number field as it is typed") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Phone");
                tester().enterText("5555555555", intoViewWithAccessibilityLabel: "Phone", traits: .none, expectedResult: "(555) 555-5555");
                tester().expect(viewTester().usingLabel("Phone")?.view, toContainText: "(555) 555-5555");
            }
            
            it("should proceed to each field in order") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                var mageServer: MageServer?;
                waitUntil { done in
                    MageServer.server(with: URL(string: "https://magetest")) { server in
                        mageServer = server;
                        done();
                    } failure: { _ in
                        
                    };
                }
                
                view = SignUpViewController(server: mageServer, andDelegate: delegate);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Sign Up");
                
                tester().enterText("username\n", intoViewWithAccessibilityLabel: "Username");
                tester().waitForFirstResponder(withAccessibilityLabel: "Display Name");
                tester().enterText("display\n", intoViewWithAccessibilityLabel: "Display Name");
                tester().waitForFirstResponder(withAccessibilityLabel: "Email");
                tester().enterText("email@email.com\n", intoViewWithAccessibilityLabel: "Email");
                tester().waitForFirstResponder(withAccessibilityLabel: "Phone");
                tester().enterText("5555555555\n", intoViewWithAccessibilityLabel: "Phone", traits: .none, expectedResult: "(555) 555-5555");
                tester().waitForFirstResponder(withAccessibilityLabel: "Password");
                tester().enterText("password\n", intoViewWithAccessibilityLabel: "Password");
                tester().waitForFirstResponder(withAccessibilityLabel: "Password Confirm");
                tester().enterText("password\n", intoViewWithAccessibilityLabel: "Password Confirm");
                
                expect(delegate?.signUpCalled).toEventually(beTrue());
                expect(delegate?.signupParameters as! [String: String]).toEventually(equal([
                    "username": "username",
                    "password": "password",
                    "passwordconfirm": "password",
                    "phone": "(555) 555-5555",
                    "email": "email@email.com",
                    "displayName": "display"
                ]))
            }
        }
    }
}
