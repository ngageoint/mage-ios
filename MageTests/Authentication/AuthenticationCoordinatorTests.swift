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
            
            var window: UIWindow!;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
//                HTTPStubs.onStubMissing { (request) in
//                    expect(true).to(beFalse(), description: "URL Request \(request.url) was not mocked");
//                }
//
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 414);
                window.autoSetDimension(.height, toSize: 896);
                
                window.makeKeyAndVisible();
                
                UserDefaults.MageServer.set("https://magetest", forKey: .baseServerUrl);
                UserDefaults.Map.set(0, forKey: .mapType);
                UserDefaults.Map.set(false, forKey: .showMGRS);
                
                Server.setCurrentEventId(1);
            }
            
            afterEach {
                HTTPStubs.removeAllStubs();
//                HTTPStubs.onStubMissing(nil);
                TestHelpers.clearAndSetUpStack();
            }
            
            it("should load the LoginViewController") {
                MageSessionManager.shared()?.setToken("oldToken");
                StoredPassword.persistToken(toKeyChain: "oldToken");
                UserDefaults.Authentication.set(true, forKey: .deviceRegistered);
                
                class Delegate: MockMageServerDelegate {
                    var urls: [URL?] = [];

                    func urlCalled(_ url: URL?, method: String?) {
                        urls.append(url);
                    }
                }
                
                let serverDelegate: Delegate = Delegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess.json", delegate: serverDelegate);
                
                let navigationController = UINavigationController();
                let delegate = MockAuthenticationCoordinatorDelegate();
                
                let coordinator: AuthenticationCoordinator = AuthenticationCoordinator.init(navigationController: navigationController, andDelegate: delegate);
                
                coordinator.start();
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")), timeout: 10, pollInterval: 1, description: "API request did not happened")
                expect(navigationController.viewControllers[0]).toEventually(beAnInstanceOf(LoginViewController.self));
            }
            
            it("should login with registered device") {
                MageSessionManager.shared()?.setToken("oldToken");
                StoredPassword.persistToken(toKeyChain: "oldToken");
                UserDefaults.Authentication.set(true, forKey: .deviceRegistered);
                
                class Delegate: MockMageServerDelegate {
                    var urls: [URL?] = [];
                    
                    func urlCalled(_ url: URL?, method: String?) {
                        urls.append(url);
                    }
                }
                
                stub(condition: isHost("magetest") && isPath("/api") ) { _ in
                    let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
                    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                }
                                
                let serverDelegate: Delegate = Delegate();
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
                
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/authorize", filePath: "authorizeLocalSuccess.json", delegate: serverDelegate);
                
                let navigationController = UINavigationController();
                window.rootViewController = navigationController;
                let delegate = MockAuthenticationCoordinatorDelegate();
                
                let coordinator: AuthenticationCoordinator = AuthenticationCoordinator.init(navigationController: navigationController, andDelegate: delegate);
                
                coordinator.start();
                
                tester().waitForView(withAccessibilityLabel: "Log In")
                tester().setText("username", intoViewWithAccessibilityLabel: "Username");
                tester().setText("password", intoViewWithAccessibilityLabel: "Password");
                
                tester().tapView(withAccessibilityLabel: "Log In");
                
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: 10, pollInterval: 1, description: "Signin request made")
                expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/authorize")), timeout: 10, pollInterval: 1, description: "Local Authorize request was not made")
                expect(navigationController.topViewController).toEventually(beAnInstanceOf(DisclaimerViewController.self), timeout: 10, pollInterval: 1, description: "Disclaimer screen was not shown");

            }
        }
    }
}
