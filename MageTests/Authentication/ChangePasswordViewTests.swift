//
//  ChangePasswordViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs

@testable import MAGE

@available(iOS 13.0, *)

class ChangePasswordViewControllerTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("ChangePasswordViewControllerTests") {
            
            var window: UIWindow?;
            var view: ChangePasswordViewController?;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();

                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                navigationController = UINavigationController();
                window = TestHelpers.getKeyWindowVisible();
                window!.rootViewController = navigationController;
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                view = nil;
                window?.resignKey();
                window = nil;
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("should load empty the Change Password View") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();

                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ChangePasswordViewController.self));
                tester().waitForView(withAccessibilityLabel: "Change");
                expect(viewTester().usingLabel("Username")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Current Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("New Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Confirm New Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Cancel")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Change")?.view).toEventuallyNot(beNil());
                let newPasswordField: UITextField = viewTester().usingLabel("New Password")?.view as! UITextField;
                expect(newPasswordField.placeholder).toEventually(equal("New Password"))
                let confirmNewPasswordField: UITextField = viewTester().usingLabel("Confirm New Password")?.view as! UITextField;
                expect(confirmNewPasswordField.placeholder).toEventually(equal("Confirm New Password"))
            }
            
            it("should alert if it could not contact the server") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                stub(condition: isHost("magetest") && isPath("/api")) { (request) -> HTTPStubsResponse in
                    serverDelegate.urls.append(request.url);
                    return HTTPStubsResponse(data: "error response".data(using: .utf8)!, statusCode: 404, headers: nil);
                }
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(ChangePasswordViewController.self));
                tester().waitForTappableView(withAccessibilityLabel: "Unable to contact the MAGE server");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Unable to contact the MAGE server"));
//                expect(alert.message).to(contain("error response"));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            // Skipping this test due to not being able to turn off auto suggest password
            xit("should proceed to each view in order") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                let expectedJsonBody: [String: String] = [
                    "username": "username",
                    "password": "password",
                    "newPassword": "newpassword",
                    "newPasswordConfirm": "newpassword"
                ]
                
                stub(condition: isHost("magetest") && isPath("/api/users/myself/password") && isMethodPUT() && hasJsonBody(expectedJsonBody)) { (request) -> HTTPStubsResponse in
                    serverDelegate.urls.append(request.url);
                        return HTTPStubsResponse(jsonObject: ["username": "username"], statusCode: 200, headers: ["Content-Type": "application/json"])
                }
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Username");
                expect(viewTester().usingLabel("Username")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Current Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("New Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Confirm New Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Cancel")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Change")?.view).toEventuallyNot(beNil());
                
                tester().enterText("username\n", intoViewWithAccessibilityLabel: "Username");
                tester().waitForFirstResponder(withAccessibilityLabel: "Current Password");
                tester().clearTextFromView(withAccessibilityLabel: "Current Password");
                tester().enterText("password\n", intoViewWithAccessibilityLabel: "Current Password");
                tester().waitForFirstResponder(withAccessibilityLabel: "New Password");
                tester().enterText("newpassword\n", intoViewWithAccessibilityLabel: "New Password");
                tester().waitForFirstResponder(withAccessibilityLabel: "Confirm New Password");
                tester().enterText("newpassword\n", intoViewWithAccessibilityLabel: "Confirm New Password");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")));
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users/myself/password")));
                
                tester().waitForTappableView(withAccessibilityLabel: "Password Has Been Changed");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Password Has Been Changed"));
                expect(alert.message).to(contain("Your password has successfully been changed.  For security purposes you will now be redirected to the login page to log back in with your new password."));
                tester().tapView(withAccessibilityLabel: "OK");
                expect((UIApplication.shared.delegate as! TestingAppDelegate).logoutCalled).to(beTrue());
            }
            
            it("should show a failure if the password could not be changed") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                let expectedJsonBody: [String: String] = [
                    "username": "username",
                    "password": "password",
                    "newPassword": "newpassword",
                    "newPasswordConfirm": "newpassword"
                ]
                
                stub(condition: isHost("magetest") && isPath("/api/users/myself/password") && isMethodPUT() && hasJsonBody(expectedJsonBody)) { (request) -> HTTPStubsResponse in
                    serverDelegate.urls.append(request.url);
                    return HTTPStubsResponse(data: "error response".data(using: .utf8)!, statusCode: 404, headers: nil)
                }
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Username");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                expect(viewTester().usingLabel("Username")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Current Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("New Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Confirm New Password")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Cancel")?.view).toEventuallyNot(beNil());
                expect(viewTester().usingLabel("Change")?.view).toEventuallyNot(beNil());
                
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Current Password");
                tester().setText("newpassword", intoViewWithAccessibilityLabel: "New Password");
                tester().setText("newpassword", intoViewWithAccessibilityLabel: "Confirm New Password");
                tester().tapView(withAccessibilityLabel: "Change");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")));
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users/myself/password")));
                
                tester().waitForTappableView(withAccessibilityLabel: "Error Changing Password");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Error Changing Password"));
                expect(alert.message).to(contain("error response"));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should not allow changing the password without the required fields") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Change");
                tester().tapView(withAccessibilityLabel: "Change");

                tester().waitForTappableView(withAccessibilityLabel: "Missing Required Fields");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Missing Required Fields"));
                expect(alert.message).to(contain("New Password"));
                expect(alert.message).to(contain("Confirm New Password"));
                expect(alert.message).to(contain("Username"));
                expect(alert.message).to(contain("Current Password"));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should ensure the passwords match") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Change");
                
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Current Password");
                tester().setText("newpassword", intoViewWithAccessibilityLabel: "New Password");
                tester().setText("newpasswordnomatch", intoViewWithAccessibilityLabel: "Confirm New Password");
                tester().tapView(withAccessibilityLabel: "Change");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")));
                
                tester().waitForTappableView(withAccessibilityLabel: "Passwords Do Not Match");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Passwords Do Not Match"));
                expect(alert.message).to(equal("Please update password fields to match."));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should ensure the new password is different than the old one") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForTappableView(withAccessibilityLabel: "Change");
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Current Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "New Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm New Password");
                tester().tapView(withAccessibilityLabel: "Change");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")));
                
                tester().waitForTappableView(withAccessibilityLabel: "Password cannot be the same as the current password");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Password cannot be the same as the current password"));
                expect(alert.message).to(equal("Please choose a new password."));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should show the password") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Show Password");
                let passwordField: UITextField = viewTester().usingLabel("New Password").view as! UITextField;
                let passwordConfirmField: UITextField = viewTester().usingLabel("Confirm New Password").view as! UITextField;
                
                tester().setText("password", intoViewWithAccessibilityLabel: "New Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm New Password");
                
                expect(passwordField.isSecureTextEntry).to(beTrue());
                expect(passwordConfirmField.isSecureTextEntry).to(beTrue());
                tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Password");
                
                expect(passwordField.isSecureTextEntry).to(beFalse());
                expect(passwordConfirmField.isSecureTextEntry).to(beFalse());
            }
            
            it("should show the current password") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "Show Current Password");
                let passwordField: UITextField = viewTester().usingLabel("Current Password").view as! UITextField;
                
                tester().setText("password", intoViewWithAccessibilityLabel: "Current Password");
                
                expect(passwordField.isSecureTextEntry).to(beTrue());
                tester().setOn(true, forSwitchWithAccessibilityLabel: "Show Current Password");
                
                expect(passwordField.isSecureTextEntry).to(beFalse());
            }
            
            it("should update the password strength meter") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "New Password");
                
                tester().enterText("turtle", intoViewWithAccessibilityLabel: "New Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Weak");
                
                tester().clearTextFromView(withAccessibilityLabel: "New Password");
                tester().enterText("Turt", intoViewWithAccessibilityLabel: "New Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Fair");
                
                tester().clearTextFromView(withAccessibilityLabel: "New Password");
                tester().enterText("Turt3", intoViewWithAccessibilityLabel: "New Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Good");
                
                tester().clearTextFromView(withAccessibilityLabel: "New Password");
                tester().enterText("Turt3!", intoViewWithAccessibilityLabel: "New Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Strong");
                
                tester().clearTextFromView(withAccessibilityLabel: "New Password");
                tester().enterText("Turt3!@@", intoViewWithAccessibilityLabel: "New Password");
                tester().expect(viewTester().usingLabel("Password Strength Label")?.view, toContainText: "Excellent");
            }
            
            it("should cancel") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                let firstView: UIViewController = UIViewController();
                navigationController?.pushViewController(firstView, animated: false);
                firstView.present(view!, animated: false, completion: nil);
                tester().waitForView(withAccessibilityLabel: "Change");
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Change")
            }
            
            it("should set the currently logged in user") {
                MageCoreDataFixtures.addUser();
                UserDefaults.standard.currentUserId = "userabc";
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                view = ChangePasswordViewController(loggedIn: false, scheme: MAGEScheme.scheme(), context: nil);
                navigationController?.pushViewController(view!, animated: false);
                tester().waitForView(withAccessibilityLabel: "Change");
                tester().expect(viewTester().usingLabel("Username")?.view, toContainText: "userabc");
            }
        }
    }
}
