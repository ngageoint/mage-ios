//
//  AuthenticationCoordinatorTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 9/29/20.
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

class MockAuthenticationCoordinatorDelegate: NSObject, AuthenticationDelegate {
    
    var authenticationSuccessfulCalled = false;
    var couldNotAuthenticateCalled = false;
    func authenticationSuccessful() {
        authenticationSuccessfulCalled = true;
    }
    
    func couldNotAuthenticate() {
        couldNotAuthenticateCalled = true;
    }
}

class AuthenticationCoordinatorTests: KIFSpec {
    
    override func spec() {
        
        describe("AuthenticationCoordinatorTests") {
            
            var window: UIWindow?;
            var coordinator: AuthenticationCoordinator?;
            var delegate: MockAuthenticationCoordinatorDelegate?;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                window = UIWindow(forAutoLayout: ());
                window?.autoSetDimension(.width, toSize: 414);
                window?.autoSetDimension(.height, toSize: 896);
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent { (_, _) in
                        done();
                    }
                }
                
                Server.setCurrentEventId(1);
                
                delegate = MockAuthenticationCoordinatorDelegate();
                navigationController = UINavigationController();
                window?.rootViewController = navigationController;
                window?.makeKeyAndVisible();
                
                coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme());
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                coordinator = nil;
                delegate = nil;
                window?.resignKey();
                window = nil;
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
                tester().waitForAnimationsToFinish();
            }
            
            it("should load the LoginViewController") {
                MageSessionManager.shared()?.setToken("oldToken");
                StoredPassword.persistToken(toKeyChain: "oldToken");
                UserDefaults.standard.deviceRegistered = true;

                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "API request did not happened")
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(LoginViewController.self));
            }
            
            it("should login with registered device") {
                UserDefaults.standard.deviceRegistered = true;
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
                                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
                
                tester().waitForView(withAccessibilityLabel: "Agree");
                tester().tapView(withAccessibilityLabel: "Agree");
                
                expect(delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
            }
            
            it("should login with an inactive user") {
                UserDefaults.standard.deviceRegistered = true;
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
                
                tester().waitForView(withAccessibilityLabel: "Agree");
                tester().tapView(withAccessibilityLabel: "Agree");
                
                expect(delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
            }
            
            it("should login with registered device and skip the disclaimer screen") {
                UserDefaults.standard.deviceRegistered = true;
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccessNoDisclaimer.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccessNoDisclaimer.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
                
                expect(delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
            }
            
            it("should login as a different user") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        MageCoreDataFixtures.addUnsyncedObservationToEvent { (_, _) in
                            done();
                        }
                    }
                }
                
                UserDefaults.standard.deviceRegistered = true;
                UserDefaults.standard.currentUserId = "userabc";
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1));
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Loss of Unsaved Data");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Loss of Unsaved Data"));
                tester().tapView(withAccessibilityLabel: "Continue");
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
                
                tester().waitForView(withAccessibilityLabel: "Agree");
                tester().tapView(withAccessibilityLabel: "Agree");
                
                expect(delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
            }
            
            it("should stop logging in as a different user") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        MageCoreDataFixtures.addUnsyncedObservationToEvent { (_, _) in
                            done();
                        }
                    }
                }
                
                UserDefaults.standard.deviceRegistered = true;
                UserDefaults.standard.currentUserId = "userabc";
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1));
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Loss of Unsaved Data");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Loss of Unsaved Data"));
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1));
            }
            
            it("should log in with an inactive user") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        done();
                    }
                }
                
                UserDefaults.standard.deviceRegistered = true;
                UserDefaults.standard.currentUserId = "userabc";
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccessInactiveUser.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                
                tester().waitForTappableView(withAccessibilityLabel: "MAGE Account Created");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("MAGE Account Created"));
                expect(alert.message).to(equal("Account created, please contact your MAGE administrator to activate your account."));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should fail to get a token") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        done();
                    }
                }
                
                UserDefaults.standard.deviceRegistered = true;
                UserDefaults.standard.currentUserId = "userabc";
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                stub(condition: isHost("magetest") && isPath("/auth/token")) { request in
                    serverDelegate.urlCalled(request.url, method: request.httpMethod);
                    return HTTPStubsResponse(data: String("Failed to get a token").data(using: .utf8)!, statusCode: 401, headers: nil);
                }
                
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Login Failed");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Login Failed"));
                expect(alert.message).to(equal("Failed to get a token"));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should not be able to log in offline with no stored password") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        done();
                    }
                }
                
                UserDefaults.standard.deviceRegistered = true;
                UserDefaults.standard.currentUserId = "userabc";
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                stub(condition: isHost("magetest") && isPath("/auth/local/signin")) { request in
                    serverDelegate.urlCalled(request.url, method: request.httpMethod);
                    return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil));
                }
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Unable to Login");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Unable to Login"));
                expect(alert.message).to(equal("We are unable to connect to the server. Please try logging in again when your connection to the internet has been restored."));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should log in offline with stored password") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        done();
                    }
                }
                
                UserDefaults.standard.deviceRegistered = true;
                UserDefaults.standard.currentUserId = "userabc";
                UserDefaults.standard.loginParameters = [
                    "serverUrl": "https://magetest",
                    "username": "username"
                ];
                StoredPassword.persistPassword(toKeyChain: "password");
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                stub(condition: isHost("magetest") && isPath("/auth/local/signin")) { request in
                    serverDelegate.urlCalled(request.url, method: request.httpMethod);
                    return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil));
                }
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Disconnected Login");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Disconnected Login"));
                expect(alert.message).to(equal("We are unable to connect to the server. Would you like to work offline until a connection to the server can be established?"));
                tester().tapView(withAccessibilityLabel: "OK, Work Offline");
                
                tester().waitForView(withAccessibilityLabel: "Agree");
                tester().tapView(withAccessibilityLabel: "Agree");
                
                expect(delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
            }
            
            it("should log in offline again with stored password") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        done();
                    }
                }
                UserDefaults.standard.loginType = "local";
                UserDefaults.standard.deviceRegistered = true;
                UserDefaults.standard.currentUserId = "userabc";
                UserDefaults.standard.loginParameters = [
                    "serverUrl": "https://magetest",
                    "username": "username"
                ];
                StoredPassword.persistPassword(toKeyChain: "password");
                
                expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                stub(condition: isHost("magetest") && isPath("/auth/local/signin")) { request in
                    serverDelegate.urlCalled(request.url, method: request.httpMethod);
                    return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil));
                }
                
                coordinator?.startLoginOnly();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Disconnected Login");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Disconnected Login"));
                expect(alert.message).to(equal("We are still unable to connect to the server to log you in. You will continue to work offline."));
                tester().tapView(withAccessibilityLabel: "OK");
                
                expect(delegate?.couldNotAuthenticateCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
            }
            
            it("should initialize the login view with a user") {
                waitUntil { done in
                    MageCoreDataFixtures.addUser { (_, _) in
                        done();
                    }
                }
                
                UserDefaults.standard.deviceRegistered = true;
                UserDefaults.standard.currentUserId = "userabc";
                                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
                
                coordinator?.startLoginOnly();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                let view: UITextField = (viewTester().usingLabel("Username")?.view as! UITextField);
                expect(view.isEnabled).to(beFalse());
                tester().expect(view, toContainText: "userabc");
            }
            
            it("should login with an unregistered device") {
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                stub(condition: isHost("magetest") && isPath("/auth/token")) { request in
                    serverDelegate.urlCalled(request.url, method: request.httpMethod);
                    return HTTPStubsResponse(data: String("device was registered").data(using: .utf8)!, statusCode: 403, headers: nil);
                }
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Registration Sent");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Registration Sent"));
                expect(alert.message).to(contain("Your device has been registered.  \nAn administrator has been notified to approve this device."));
                tester().tapView(withAccessibilityLabel: "OK");
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(LoginViewController.self));
            }
            
            it("should login with registered device and disagree to the disclaimer") {
                UserDefaults.standard.deviceRegistered = true;
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Sign In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Sign In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
                
                tester().waitForView(withAccessibilityLabel: "Disagree");
                tester().tapView(withAccessibilityLabel: "Disagree");
                
                expect((UIApplication.shared.delegate as! TestingAppDelegate).logoutCalled).to(beTrue());
            }
            
            it("should create an account") {
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api/users", filePath: "signupSuccess.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForTappableView(withAccessibilityLabel: "Sign Up Here")
                tester().tapView(withAccessibilityLabel: "Sign Up Here");
                
                tester().waitForView(withAccessibilityLabel: "Display Name");

                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");

                tester().waitForView(withAccessibilityLabel: "Sign Up");
                tester().tapView(withAccessibilityLabel: "Sign Up");

                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Sign Up request made")

                tester().waitForTappableView(withAccessibilityLabel: "Account Created");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Account Created"));
                expect(alert.message).to(contain("Your account is now active."));
                tester().tapView(withAccessibilityLabel: "OK");

                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(LoginViewController.self));
            }
            
            it("should create an inactive account") {
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api/users", filePath: "signupSuccessInactive.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForTappableView(withAccessibilityLabel: "Sign Up Here")
                tester().tapView(withAccessibilityLabel: "Sign Up Here");
                
                tester().waitForView(withAccessibilityLabel: "Display Name");
                
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
                
                tester().waitForView(withAccessibilityLabel: "Sign Up");
                tester().tapView(withAccessibilityLabel: "Sign Up");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Sign Up request made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Account Created");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("Account Created"));
                expect(alert.message).to(contain("An administrator must approve your account before you can login"));
                tester().tapView(withAccessibilityLabel: "OK");
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(LoginViewController.self));
            }
            
            it("should fail to create an account") {
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                stub(condition: isHost("magetest") && isPath("/api/users") ) { request in
                    serverDelegate.urlCalled(request.url, method: request.httpMethod);
                    return HTTPStubsResponse(data: String("error message").data(using: .utf8)!, statusCode: 503, headers: nil);
                }
                
                coordinator?.start();
                
                tester().waitForTappableView(withAccessibilityLabel: "Sign Up Here")
                tester().tapView(withAccessibilityLabel: "Sign Up Here");
                
                tester().waitForView(withAccessibilityLabel: "Display Name");
                
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
                
                tester().waitForView(withAccessibilityLabel: "Sign Up");
                tester().tapView(withAccessibilityLabel: "Sign Up");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Sign Up request made")
                
                tester().waitForTappableView(withAccessibilityLabel: "Error Creating Account");
                let alert: UIAlertController = (navigationController?.presentedViewController as! UIAlertController);
                expect(alert.title).to(equal("Error Creating Account"));
                expect(alert.message).to(equal("error message"));
                tester().tapView(withAccessibilityLabel: "OK");
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(SignUpViewController.self));
            }
            
            it("should cancel creating an account") {
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                
                coordinator?.start();
                
                tester().waitForTappableView(withAccessibilityLabel: "Sign Up Here")
                tester().tapView(withAccessibilityLabel: "Sign Up Here");
                
                tester().waitForView(withAccessibilityLabel: "Display Name");
                
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
                
                tester().waitForView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(LoginViewController.self));
            }
            
            it("should show the change server url view") {
                UserDefaults.standard.baseServerUrl = nil;
                
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();

                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "ServerURLView")

                tester().setText("https://magetest", intoViewWithAccessibilityLabel: "Server URL");
                tester().tapView(withAccessibilityLabel: "OK");

                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "API request not made")
                expect(UserDefaults.standard.baseServerUrl).toEventually(equal("https://magetest"));
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(LoginViewController.self));
            }
            
            it("should show the change server url view and then cancel") {
                let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                coordinator?.start();
                
                tester().waitForView(withAccessibilityLabel: "Server URL");
                tester().tapView(withAccessibilityLabel: "Server URL");
                
                tester().waitForView(withAccessibilityLabel: "ServerURLView")
                
                tester().setText("https://magetestcancel", intoViewWithAccessibilityLabel: "Server URL");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                expect(UserDefaults.standard.baseServerUrl).to(equal("https://magetest"));
                expect(navigationController?.topViewController).toEventually(beAnInstanceOf(LoginViewController.self));
            }
        }
    }
}
