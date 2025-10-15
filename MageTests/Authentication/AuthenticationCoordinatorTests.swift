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
import ViewInspector

@testable import MAGE
import UIKit

@available(iOS 13.0, *)

class AuthenticationCoordinatorTests: AsyncMageCoreDataTestCase {
    
//    var spy: AuthenticationCoordinatorSpy!
//
//    var window: UIWindow?
//    var coordinator: AuthenticationCoordinator?
//    var delegate: MockAuthenticationCoordinatorDelegate?
//    var navigationController: UINavigationController?
    
//    override func setUp() async throws {
//        try await super.setUp()
//        
//        UserDefaults.standard.baseServerUrl = "https://magetest";
//        UserDefaults.standard.mapType = 0;
//        UserDefaults.standard.locationDisplay = .latlng;
//        
//        MageSessionManager.shared()?.clearToken()
//        
//        Server.setCurrentEventId(1)
//        MageCoreDataFixtures.addEvent()
//        delegate = MockAuthenticationCoordinatorDelegate()
//        
//        await setupNavigationController()
//        
//        coordinator = AuthenticationCoordinator(
//            navigationController: navigationController,
//            andDelegate: delegate,
//            andScheme: MAGEScheme.scheme(),
//            context: context
//        )
//        
//        spy = AuthenticationCoordinatorSpy(
//            navigationController: navigationController,
//            andDelegate: delegate,
//            andScheme: MAGEScheme.scheme(),
//            context: context
//        )
//        
//        stubServerResponse()
//    }
//    
//    @MainActor
//    func setupNavigationController() {
//        window = TestHelpers.getKeyWindowVisible()
//        navigationController = UINavigationController()
//        navigationController?.isNavigationBarHidden = true
//        window?.rootViewController = navigationController
//        window?.makeKeyAndVisible()
//    }
//    
//    override func tearDown() async throws {
//        try await super.tearDown()
//        await tearDownNavigationController()
//        coordinator = nil
//        delegate = nil
//        UserDefaults.standard.clearAll()
//        
//        MageSessionManager.shared()?.clearToken()
//    }
//    
//    @MainActor
//    func tearDownNavigationController() {
//        navigationController?.viewControllers = []
//        window?.rootViewController?.dismiss(animated: false)
//        window?.rootViewController = nil
//        navigationController = nil
//    }
//    
//    func stubServerResponse() {
//        let mockServerDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(
//            url: "https://magetest/api/server",
//            filePath: "server_response.json",
//            delegate: mockServerDelegate
//        )
//    }
//
//    func testShowLoginViewForServerCalled() {
//        let expectation = self.expectation(description: "Server request should complete")
//        
//        guard let testUrl = URL(string: "https://magetest") else {
//            XCTFail("\nFailed to create URL instance\n")
//            return
//        }
//        
//        let testServer = MageServer(url: testUrl)
//
//        spy.start(testServer) // Calls showLoginViewForServer internally
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            XCTAssertTrue(self.spy.showLoginViewForServerCalled, "Expected showLoginViewForServer to be called")
//            XCTAssertEqual(self.spy.showLoginViewForServerParam, testServer, "Expected the correct MageServer instance to be passed")
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 1, handler: nil)
//    }
//    
//    func testShouldLoadTheLoginViewController() {
//        // Set a fake "oldToken" so we can validate it gets changed.
//        // TODO: Why are we doing this in 2 different places?
//        MageSessionManager.shared()?.setToken("oldToken");
//        StoredPassword.persistToken(toKeyChain: "oldToken");
//        UserDefaults.standard.deviceRegistered = true;
//
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess6.json", delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!, success: { server in
//                mageServer = server;
//                done();
//            }, failure: { _ in
//                
//            });
//        }
//        
//        coordinator?.start(mageServer);
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "API request did not happened")
//        expect(self.navigationController?.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self));
//    }
//
//    @MainActor
//    func testLocalLogin_TriggersSigninAndTokenRequests() async throws {
//        // Arrange
//        let nav = UINavigationController()
//        let delegate = MockAuthenticationCoordinatorDelegate()
//        let coordinator = AuthenticationCoordinator(
//            navigationController: nav,
//            andDelegate: delegate,
//            andScheme: MAGEScheme.scheme(),
//            context: context
//        )!
//        
//        UserDefaults.standard.baseServerUrl = "https://magetest"
//        UserDefaults.standard.deviceRegistered = true
//        
//        // stub the API, signin, token
//        let serverDelegate = MockMageServerDelegate()
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api/server", filePath: "server_response.json", delegate: serverDelegate)
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess6.json", delegate: serverDelegate)
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate)
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate)
//
//        // Fetch a server and start coordinator (populates authenticationModules, etc.)
//        let server: MageServer = await TestHelpers.getTestServer()
//        coordinator.start(server)
//        
//        // simulate view calling into the coordinator with LoginDelegate
//        let params: [String: Any] = [
//            "username": "username",
//            "password": "password",
//            "uid": "uuid",
//            "strategy": ["identifier": "local"],
//            "appVersion": "6.0.0"
//        ]
//        
//        coordinator.login(withParameters: params, withAuthenticationStrategy: "local", complete: { _, _ in })
//        
//        // Assert: wait asynchronously for both URLs to appear
//        let signinURL = URL(string: "https://magetest/auth/local/signin")!
//        let tokenURL  = URL(string: "https://magetest/auth/token")!
//
//        let expectedSignin = expectation(description: "signin called")
//        let expectedToken = expectation(description: "token called")
//        
//        Task { [weak serverDelegate] in
//            while !(serverDelegate?.urls.contains(signinURL) ?? false) {
//                try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
//            }
//            expectedSignin.fulfill()
//        }
//
//        Task { [weak serverDelegate] in
//            while !(serverDelegate?.urls.contains(tokenURL) ?? false) {
//                try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
//            }
//            expectedToken.fulfill()
//        }
//        
//        await fulfillment(of: [expectedSignin, expectedToken], timeout: 3.0)
//    }
//    
//    func testShouldLoginWithRegisteredDevice() {
//        UserDefaults.standard.deviceRegistered = true;
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//                        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
//                        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!, success: { server in
//                mageServer = server;
//                done();
//            }, failure: { _ in
//                
//            });
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
//        
//        tester().waitForView(withAccessibilityLabel: "AGREE");
//        tester().tapView(withAccessibilityLabel: "AGREE");
//        
//        expect(self.delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
//    }
//          
//    func testShouldLoginWithAnInactiveUser() {
//        UserDefaults.standard.deviceRegistered = true;
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
//        
//        tester().waitForView(withAccessibilityLabel: "AGREE");
//        tester().tapView(withAccessibilityLabel: "AGREE");
//        
//        expect(self.delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
//    }
//            
//    func testShouldLoginWithRegisteredDeviceAndSkipTheDisclaimerScreen() {
//        UserDefaults.standard.deviceRegistered = true;
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6NoDisclaimer.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccessNoDisclaimer.json", delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
//            
//        expect(self.delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
//    }
//            
//    func testShouldLoginAsADifferentUser() {
//        let _ = MageCoreDataFixtures.addUser();
//        MageCoreDataFixtures.addUnsyncedObservationToEvent();
//        
//        UserDefaults.standard.deviceRegistered = true;
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1));
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Loss of Unsaved Data");
//        let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
//        expect(alert.title).to(equal("Loss of Unsaved Data"));
//        tester().tapView(withAccessibilityLabel: "Continue");
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
//        
//        tester().waitForView(withAccessibilityLabel: "AGREE");
//        tester().tapView(withAccessibilityLabel: "AGREE");
//        
//        expect(self.delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
//    }
//            
//    func testShouldStopLoggingInAsDifferentUser() {
//        MageCoreDataFixtures.addUser();
//        MageCoreDataFixtures.addUnsyncedObservationToEvent();
//        
//        UserDefaults.standard.deviceRegistered = true;
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1));
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Loss of Unsaved Data");
//        let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
//        expect(alert.title).to(equal("Loss of Unsaved Data"));
//        tester().tapView(withAccessibilityLabel: "Cancel");
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1));
//    }
//         
//    func testShouldLogInWithAnInactiveUser() {
//        MageCoreDataFixtures.addUser();
//        
//        UserDefaults.standard.deviceRegistered = true;
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccessInactiveUser.json", delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        
//        tester().waitForTappableView(withAccessibilityLabel: "MAGE Account Created");
//        let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
//        expect(alert.title).to(equal("MAGE Account Created"));
//        expect(alert.message).to(equal("Account created, please contact your MAGE administrator to activate your account."));
//        tester().tapView(withAccessibilityLabel: "OK");
//    }
//            
//    func testShouldFailToGetToken() {
//        MageCoreDataFixtures.addUser();
//        
//        UserDefaults.standard.deviceRegistered = true;
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        
//        stub(condition: isHost("magetest") && isPath("/auth/token")) { request in
//            serverDelegate.urlCalled(request.url, method: request.httpMethod);
//            return HTTPStubsResponse(data: String("Failed to get a token").data(using: .utf8)!, statusCode: 401, headers: nil);
//        }
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
//        
//        tester().waitForView(withAccessibilityLabel: "Login Failed");
//        let view: UITextView = (viewTester().usingLabel("Login Failed")?.view as! UITextView);
//        expect(view.isHidden).to(beFalse());
//        expect(view.attributedText.string).to(contain("Failed to get a token"));
//    }
//            
//    func testShouldNotBeAbleToLogInOfflineWithNoStoredPassword() {
//        MageCoreDataFixtures.addUser();
//        
//        UserDefaults.standard.deviceRegistered = true;
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        stub(condition: isHost("magetest") && isPath("/auth/local/signin")) { request in
//            serverDelegate.urlCalled(request.url, method: request.httpMethod);
//            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil));
//        }
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Unable to Login");
//        let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
//        expect(alert.title).to(equal("Unable to Login"));
//        expect(alert.message).to(equal("We are unable to connect to the server. Please try logging in again when your connection to the internet has been restored."));
//        tester().tapView(withAccessibilityLabel: "OK");
//    }
//            
//    func testShouldLogInOfflineWithStoredPassword() {
//        MageCoreDataFixtures.addUser();
//        
//        UserDefaults.standard.deviceRegistered = true;
//        UserDefaults.standard.currentUserId = "userabc";
//        UserDefaults.standard.loginParameters = [
//            "serverUrl": "https://magetest",
//            "username": "username"
//        ];
//        StoredPassword.persistPassword(toKeyChain: "password");
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        stub(condition: isHost("magetest") && isPath("/auth/local/signin")) { request in
//            serverDelegate.urlCalled(request.url, method: request.httpMethod);
//            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil));
//        }
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Disconnected Login");
//        let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
//        expect(alert.title).to(equal("Disconnected Login"));
//        expect(alert.message).to(equal("We are unable to connect to the server. Would you like to work offline until a connection to the server can be established?"));
//        tester().tapView(withAccessibilityLabel: "OK, Work Offline");
//        
//        tester().waitForView(withAccessibilityLabel: "AGREE");
//        tester().tapView(withAccessibilityLabel: "AGREE");
//        
//        expect(self.delegate?.authenticationSuccessfulCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
//    }
//            
//    func testShouldLogInOfflineAgainWithStoredPassword() {
//        MageCoreDataFixtures.addUser();
//        UserDefaults.standard.loginType = "offline";
//        UserDefaults.standard.deviceRegistered = true;
//        UserDefaults.standard.currentUserId = "userabc";
//        UserDefaults.standard.loginParameters = [
//            "serverUrl": "https://magetest",
//            "username": "username"
//        ];
//        StoredPassword.persistPassword(toKeyChain: "password");
//        
//        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0));
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        stub(condition: isHost("magetest") && isPath("/auth/local/signin")) { request in
//            serverDelegate.urlCalled(request.url, method: request.httpMethod);
//            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil));
//        }
//        
//        coordinator?.startLoginOnly();
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Disconnected Login");
//        let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
//        expect(alert.title).to(equal("Disconnected Login"));
//        expect(alert.message).to(equal("We are still unable to connect to the server to log you in. You will continue to work offline."));
//        tester().tapView(withAccessibilityLabel: "OK");
//        
//        expect(self.delegate?.couldNotAuthenticateCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Authentication Successful was never called");
//    }
//            
//    func testShouldInitializeLoginViewWithUser() {
//        MageCoreDataFixtures.addUser();
//        
//        UserDefaults.standard.deviceRegistered = true;
//        UserDefaults.standard.currentUserId = "userabc";
//                        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
//        
//        coordinator?.startLoginOnly();
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        let view: UITextField = (viewTester().usingLabel("Username")?.view as! UITextField);
//        expect(view.isEnabled).to(beFalse());
//        tester().expect(view, toContainText: "userabc");
//    }
//            
//    func testShouldLoginWithAnUnregisteredDevice() {
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        
//        stub(condition: isHost("magetest") && isPath("/auth/token")) { request in
//            serverDelegate.urlCalled(request.url, method: request.httpMethod);
//            return HTTPStubsResponse(data: String("device was registered").data(using: .utf8)!, statusCode: 403, headers: nil);
//        }
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
//        
//        tester().waitForView(withAccessibilityLabel: "Registration Sent");
//        let view: UITextView = (viewTester().usingLabel("Registration Sent")?.view as! UITextView);
//        expect(view.isHidden).to(beFalse());
//        expect(view.attributedText.string).to(contain("Your device has been registered."));
//        expect(view.attributedText.string).to(contain("An administrator has been notified to approve this device."));
//        
//        expect(self.navigationController?.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self));
//    }
//            
//    func testShouldLoginWithRegisteredDeviceAndDisagreeToTheDisclaimer() {
//        UserDefaults.standard.deviceRegistered = true;
//        
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate);
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForView(withAccessibilityLabel: "Sign In")
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        
//        tester().tapView(withAccessibilityLabel: "Sign In");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/local/signin")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signin request made")
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/auth/token")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Token request was not made")
//        
//        tester().waitForView(withAccessibilityLabel: "DISAGREE");
//        tester().tapView(withAccessibilityLabel: "DISAGREE");
//        
//        expect((UIApplication.shared.delegate as! TestingAppDelegate).logoutCalled).to(beTrue());
//    }
//            
//    func testShouldCreateAnAccount() {
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api/users/signups", filePath: "signups.json", delegate: serverDelegate);
//        
//        MockMageServer.stubJSONSuccessRequest(
//            url: "https://magetest/api/users/signups/verifications",
//            filePath: "signupSuccess.json",
//            jsonBody: [
//                "username" : "username",
//                "password" : "password",
//                "passwordconfirm": "password",
//                "displayName" : "display",
//                "phone": "",
//                "email": "",
//                "captchaText" : "captcha"
//            ],
//            delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Sign Up Here")
//        tester().tapView(withAccessibilityLabel: "Sign Up Here");
//        
//        tester().waitForView(withAccessibilityLabel: "Display Name");
//        tester().enterText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().tapView(withAccessibilityLabel: "Display Name");
//        tester().waitForFirstResponder(withAccessibilityLabel: "Display Name");
//        tester().enterText("display", intoViewWithAccessibilityLabel: "Display Name");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users/signups")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Captcha request made")
//        
//        tester().setText("captcha", intoViewWithAccessibilityLabel: "Captcha");
//        
//        tester().waitForView(withAccessibilityLabel: "Sign Up");
//        tester().tapView(withAccessibilityLabel: "Sign Up");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users/signups/verifications")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signup request made")
//
//        tester().waitForTappableView(withAccessibilityLabel: "Account Created");
//        let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
//        expect(alert.title).to(equal("Account Created"));
//        expect(alert.message).to(contain("Your account is now active."));
//        tester().tapView(withAccessibilityLabel: "OK");
//
//        expect(self.navigationController?.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self));
//    }
//            
//    func testShouldCreateAnInactiveAccount() {
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api/users/signups", filePath: "signups.json", delegate: serverDelegate);
//        
//        MockMageServer.stubJSONSuccessRequest(
//            url: "https://magetest/api/users/signups/verifications",
//            filePath: "signupSuccessInactive.json",
//            jsonBody: [
//                "username" : "username",
//                "password" : "password",
//                "passwordconfirm": "password",
//                "displayName" : "display",
//                "phone": "",
//                "email": "",
//                "captchaText" : "captcha"
//            ],
//            delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Sign Up Here")
//        tester().tapView(withAccessibilityLabel: "Sign Up Here");
//        
//        tester().waitForView(withAccessibilityLabel: "Display Name");
//        
//        tester().enterText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().tapView(withAccessibilityLabel: "Display Name");
//        tester().enterText("display", intoViewWithAccessibilityLabel: "Display Name");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users/signups")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Captcha request made")
//        
//        tester().setText("captcha", intoViewWithAccessibilityLabel: "Captcha");
//        
//        tester().waitForView(withAccessibilityLabel: "Sign Up");
//        tester().tapView(withAccessibilityLabel: "Sign Up");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users/signups/verifications")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Signup request made")
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Account Created");
//        let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
//        expect(alert.title).to(equal("Account Created"));
//        expect(alert.message).to(contain("An administrator must approve your account before you can login"));
//        tester().tapView(withAccessibilityLabel: "OK");
//        
//        expect(self.navigationController?.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self));
//    }
//   
//    func testShouldFailToCreateAccount() {
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//        
//        stub(condition: isHost("magetest") && isPath("/api/users/signups/verifications") ) { request in
//            serverDelegate.urlCalled(request.url, method: request.httpMethod);
//            return HTTPStubsResponse(data: String("error message").data(using: .utf8)!, statusCode: 503, headers: nil);
//        }
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Sign Up Here")
//        tester().tapView(withAccessibilityLabel: "Sign Up Here");
//        
//        tester().waitForView(withAccessibilityLabel: "Display Name");
//        
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
//        
//        tester().waitForView(withAccessibilityLabel: "Sign Up");
//        tester().tapView(withAccessibilityLabel: "Sign Up");
//        
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api/users/signups/verifications")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "Sign Up request made")
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Error Creating Account");
//        let alert: UIAlertController = (navigationController?.presentedViewController as! UIAlertController);
//        expect(alert.title).to(equal("Error Creating Account"));
//        expect(alert.message).to(equal("error message"));
//        tester().tapView(withAccessibilityLabel: "OK");
//        
//        expect(self.navigationController?.topViewController).toEventually(beAnInstanceOf(SignUpViewController.self));
//    }
//            
//    func testShouldCancelCreatingAnAccount() {
//        stub(condition: isHost("magetest") && isPath("/api") ) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().waitForTappableView(withAccessibilityLabel: "Sign Up Here")
//        tester().tapView(withAccessibilityLabel: "Sign Up Here");
//        
//        tester().waitForView(withAccessibilityLabel: "Display Name");
//        
//        tester().setText("username", intoViewWithAccessibilityLabel: "Username");
//        tester().setText("display", intoViewWithAccessibilityLabel: "Display Name");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Password");
//        tester().setText("password", intoViewWithAccessibilityLabel: "Confirm Password");
//        
//        TestHelpers.printAllAccessibilityLabelsInWindows()
//        tester().waitForView(withAccessibilityLabel: "CANCEL");
//        tester().tapView(withAccessibilityLabel: "CANCEL");
//        
//        expect(self.navigationController?.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self));
//    }
//            
//    func testShouldTellTheDelegateToShowTheChangeServerUrlView() {
//        let serverDelegate: MockMageServerDelegate = MockMageServerDelegate();
//
//        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess6.json", delegate: serverDelegate);
//        
//        var mageServer: MageServer?;
//        waitUntil { done in
//            MageServer.server(url: URL(string: "https://magetest")!) { server in
//                mageServer = server;
//                done();
//            } failure: { _ in
//                
//            };
//        }
//        
//        coordinator?.start(mageServer);
//        
//        tester().tapView(withAccessibilityLabel: "Server URL")
//
//        expect(serverDelegate.urls).toEventually(contain(URL(string: "https://magetest/api")), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "API request not made")
//        expect(self.delegate?.changeServerURLCalled).to(beTrue());
//    }
//    
//    
//    func testStartLoginOnly() {
//        let expectation = self.expectation(description: "Server request should complete")
//
//        stub(condition: isHost("magetest") && isPath("/api")) { _ in
//            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
//            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
//        }
//
//        coordinator?.startLoginOnly()
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            XCTAssertNotNil(self.coordinator?.server, "Expected a valid MageServer to be set")
//            XCTAssertNotNil(self.navigationController?.topViewController as? LoginHostViewController, "Expected LoginHostViewController to be shown")
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 1, handler: nil)
//    }
    
}
