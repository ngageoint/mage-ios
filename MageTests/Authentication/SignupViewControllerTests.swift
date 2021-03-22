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
import OHHTTPStubs
import Kingfisher

@testable import MAGE

@available(iOS 13.0, *)

class MockSignUpDelegate: NSObject, SignupDelegate {

    
    var signupParameters: [AnyHashable : Any]?;
    var url: URL?;
    var signUpCalled = false;
    var signupCanceledCalled = false;
    var getCaptchaCalled = false;
    var captchaUsername: String?;
    
    func getCaptcha(_ username: String, completion: @escaping (String) -> Void) {
        getCaptchaCalled = true;
        captchaUsername = username;
    }
    
    func signup(withParameters parameters: [AnyHashable : Any], completion: @escaping (HTTPURLResponse) -> Void) {
        signUpCalled = true;
        signupParameters = parameters;
    }
    
    func signupCanceled() {
        signupCanceledCalled = true;
    }
}

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
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                MageCoreDataFixtures.addEvent();
                
                Server.setCurrentEventId(1);
                
                delegate = MockSignUpDelegate();
                navigationController = UINavigationController();
                window?.rootViewController = navigationController;
                window?.makeKeyAndVisible();
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                view = nil;
                delegate = nil;
                window?.resignKey();
                window = nil;
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
                
            }
            
            it("should load the SignUpViewCOntroller server version 5") {
                view = SignUpViewController_Server5(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).to(beAnInstanceOf(SignUpViewController_Server5.self));
                expect(viewTester().usingLabel("Username")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Display Name")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Email")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Phone")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Password")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Confirm Password")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Cancel")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Sign Up")?.view).toNot(beNil());
                tester().waitForView(withAccessibilityLabel: "Version");
                let versionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String;
                tester().expect(viewTester().usingLabel("Version").view, toContainText: "v\(versionString)");
                tester().expect(viewTester().usingLabel("Server URL").view, toContainText: "https://magetest");
            }
            
            it("should load the SignUpViewController") {
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).to(beAnInstanceOf(SignUpViewController.self));
                expect(viewTester().usingLabel("Username")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Display Name")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Email")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Phone")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Password")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Confirm Password")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Cancel")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Sign Up")?.view).toNot(beNil());
                expect(viewTester().usingLabel("Captcha")?.view).toNot(beNil());
                tester().waitForView(withAccessibilityLabel: "Version");
                let versionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String;
                tester().expect(viewTester().usingLabel("Version").view, toContainText: "v\(versionString)");
                tester().expect(viewTester().usingLabel("Server URL").view, toContainText: "https://magetest");
            }
            
            it("should not allow signup without required fields") {
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);

                tester().waitForView(withAccessibilityLabel: "Sign Up");
                tester().tapView(withAccessibilityLabel: "Sign Up");
                
                tester().waitForTappableView(withAccessibilityLabel: "Missing Required Fields");
                let alert: UIAlertController = (navigationController?.presentedViewController as! UIAlertController);
                expect(alert.title).to(equal("Missing Required Fields"));
                expect(alert.message).to(contain("Password"));
                expect(alert.message).to(contain("Confirm Password"));
                expect(alert.message).to(contain("Username"));
                expect(alert.message).to(contain("Display Name"));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should not allow signup with passwords that do not match") {
                
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Sign Up");
                
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("passwordsthatdonotmatch", intoViewWithAccessibilityLabel: "Confirm Password");
                
                tester().tapView(withAccessibilityLabel: "Sign Up");
                
                tester().waitForTappableView(withAccessibilityLabel: "Passwords Do Not Match");
                let alert: UIAlertController = (navigationController?.presentedViewController as! UIAlertController);
                expect(alert.title).to(equal("Passwords Do Not Match"));
                expect(alert.message).to(contain("Please update password fields to match."));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should signup") {
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Sign Up");
                
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
                tester().enterText("5555555555", intoViewWithAccessibilityLabel: "Phone", traits: .none, expectedResult: "(555) 555-5555");
                tester().setText("email@email.com", intoViewWithAccessibilityLabel: "Email");
                tester().setText("captcha", intoViewWithAccessibilityLabel: "Captcha");
                
                tester().tapView(withAccessibilityLabel: "Sign Up");
                
                expect(delegate?.signUpCalled).to(beTrue());
                expect(delegate?.signupParameters as! [String: String]).to(equal([
                    "username": "username",
                    "password": "password",
                    "passwordconfirm": "password",
                    "phone": "(555) 555-5555",
                    "email": "email@email.com",
                    "displayName": "display",
                    "captchaText": "captcha"
                ]))
            }
            
            it("should cancel") {
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                expect(delegate?.signupCanceledCalled).to(beTrue());
            }
            
            it("should show the password") {
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Show Password");
                let passwordField: UITextField = viewTester().usingLabel("Password").view as! UITextField;
                let passwordConfirmField: UITextField = viewTester().usingLabel("Confirm Password").view as! UITextField;

                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
                
                expect(passwordField.isSecureTextEntry).to(beTrue());
                expect(passwordConfirmField.isSecureTextEntry).to(beTrue());
                tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Password");
                
                
                expect(passwordField.isSecureTextEntry).to(beFalse());
                expect(passwordConfirmField.isSecureTextEntry).to(beFalse());
            }
            
            it("should update the password strength meter") {
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Password");
                // this is entirely to stop iOS from suggesting a password
                tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Password");
                
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
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Phone");
                tester().enterText("5555555555", intoViewWithAccessibilityLabel: "Phone", traits: .none, expectedResult: "(555) 555-5555");
                tester().expect(viewTester().usingLabel("Phone")?.view, toContainText: "(555) 555-5555");
            }
            
            // cannot fully test this due to being unable to disable the password auto-suggest
            it("should proceed to each field in order") {
                view = SignUpViewController(delegate: delegate, andScheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Sign Up");
                
                tester().enterText("username\n", intoViewWithAccessibilityLabel: "Username");
                tester().waitForFirstResponder(withAccessibilityLabel: "Display Name");
                tester().enterText("display\n", intoViewWithAccessibilityLabel: "Display Name");
                tester().waitForFirstResponder(withAccessibilityLabel: "Email");
                tester().enterText("email@email.com\n", intoViewWithAccessibilityLabel: "Email");
                tester().waitForFirstResponder(withAccessibilityLabel: "Phone");
                tester().enterText("5555555555", intoViewWithAccessibilityLabel: "Phone", traits: .none, expectedResult: "(555) 555-5555");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
                tester().setText("captcha", intoViewWithAccessibilityLabel: "Captcha");
                tester().tapView(withAccessibilityLabel: "Sign Up")
                
                expect(delegate?.signUpCalled).to(beTrue());
                expect(delegate?.signupParameters as! [String: String]).toEventually(equal([
                    "username": "username",
                    "password": "password",
                    "passwordconfirm": "password",
                    "phone": "(555) 555-5555",
                    "email": "email@email.com",
                    "displayName": "display",
                    "captchaText": "captcha"
                ]))
            }
        }
    }
}
