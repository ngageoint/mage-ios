//
//  AuthenticationCoordinator_FlowTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/28/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Nimble
import OHHTTPStubs

@testable import MAGE

@MainActor
final class AuthenticationCoordinator_FlowTests: AsyncMageCoreDataTestCase {
    
//    var nav: UINavigationController!
//    var delegate: MockAuthenticationCoordinatorDelegate!
//    var coordinator: AuthenticationCoordinator!
//    var net: MockMageServerDelegate!
//    
//    // MARK: - Lifecycle
//    
//    override func setUp() async throws {
//        try await super.setUp()
//        
//        _ = MageSessionManager.shared()
//        
//        net = MockMageServerDelegate()
//        Stubs.removeAll()
//        Stubs.api(delegate: net)    // /api and /apa/server
//        Stubs.userAssetsNoop()
//
//        HTTPStubs.onStubActivation { [weak self] request, _, response in
//            guard let self, let url = request.url else { return }
//            self.net?.urlCalled(url, method: request.httpMethod)
//            print("[STUB] Matched \(url.absoluteString) -> \(response.statusCode)")
//        }
//
//        // Defaults common to many tests
//        UserDefaults.standard.baseServerUrl = TestURLs.base
//        UserDefaults.standard.deviceRegistered = true
//        UserDefaults.standard.set(true, forKey: "showDisclaimer")  // opt-in; tests override when needed
//        
//        nav = UINavigationController()
//        let win = TestHelpers.getKeyWindowVisible()
//        win.rootViewController = nav
//        win.makeKeyAndVisible()
//        
//        delegate = MockAuthenticationCoordinatorDelegate()
//        
//        coordinator = AuthenticationCoordinator(
//            navigationController: nav,
//            andDelegate: delegate,
//            andScheme: MAGEScheme.scheme(),
//            context: context
//        )
//    }
//    
//    override func tearDown() async throws {
//        // 1) Remove stubs first so nothing new starts
//        Stubs.removeAll()
//        
//        // 2) Cancel any in-flight requests and let them finish canceling
//        let session = MageSessionManager.shared().session
//        await session.cancelAllTasksAndWaitASmidge()
//
//        // 3) Now it's safe to invalidate & clean up
//        session.invalidateAndCancel()
//        
//        coordinator = nil
//        delegate = nil
//        nav = nil
//        UserDefaults.standard.clearAll()
//        
//        try await super.tearDown()
//    }
//    
//    // MARK: - Helpers
//    
//    private func server() async throws -> MageServer {
//        let url = URL(string: TestURLs.base)!
//        return try await withCheckedThrowingContinuation { (c: CheckedContinuation<MageServer, Error>) in
//            MageServer.server(url: url, success: { server in
//                c.resume(returning: server)
//            }, failure: { error in
//                c.resume(throwing: error)
//            })
//        }
//    }
//    
//    private func loginParams(
//        username: String = "username",
//        password: String = "password"
//    ) -> [AnyHashable: Any] {
//        return [
//            "username": username,
//            "password": password,
//            "uid": "uuid",
//            "strategy": ["identifier": "local"],
//            "appVersion": (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
//        ]
//    }
//    
//    private func waitForURLs(_ urls: [URL], timeout: TimeInterval = 2) {
//        for u in urls {
//            expect(self.net.urls).toEventually(contain(u), timeout: .seconds(Int(timeout)), pollInterval: .milliseconds(100))
//        }
//    }
//    
//    private func topAlertTitle(timeout: TimeInterval = 2) -> String? {
//        var title: String?
//        let deadline = Date().addingTimeInterval(timeout)
//        while Date() < deadline {
//            if let alert = nav.presentedViewController as? UIAlertController {
//                title = alert.title
//                break
//            }
//            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
//        }
//        return title
//    }
//    
//    private func startWithAuthSuccess() async throws {
//        Stubs.authSuccess(delegate: net)
//        let s = try await server()
//        coordinator.start(s)
//    }
//    
//
//    func test_Minimal_HitsAPI() async throws {
//        
//        HTTPStubs.removeAllStubs()
//        
//        let hit = expectation(description: "/api was called")
//        
//        let u = URL(string: TestURLs.api)!  // https://magetest/api
//        
//        HTTPStubs.stubRequests(passingTest: { req in
//            guard let url = req.url else { return false }
//            return url.host == u.host && url.path == u.path
//        }) { _ in
//            // Fulfill as soon as the stub matches
//            hit.fulfill()
//            
//            // Return the same JSON the app expects
//            let path = Bundle(for: _AuthTestKitBundleSentinel.self)
//                .path(forResource: "apiSuccess6.json", ofType: nil)!
//            
//            return HTTPStubsResponse(
//                fileAtPath: path,
//                statusCode: 200,
//                headers: ["Content-Type": "application/json"]
//            )
//            .responseTime(0.01)
//        }
//        
//        // Act
//        let s = try await server()
//        coordinator.start(s)
//        
//        // Assert
//        await fulfillment(of: [hit], timeout: 2.0)
//    }
//    
//    func test_Start_HitsAPI() async throws {
//        HTTPStubs.removeAllStubs()
//        let apiHit = expectation(description: "/api hit")
//        
//        _ = Stubs.installJSONStub(
//            urlString: TestURLs.api,
//            file: "apiSuccess6.json",
//            delegate: net,
//            onHit: { apiHit.fulfill() }
//        )
//
//        let s = try await server()
//        coordinator.start(s)
//        
//        await fulfillment(of: [apiHit], timeout: 2.0)
//    }
//    
//    
//    // MARK: - Core: local login makes signin + token
//    func test_LocalLogin_HitsSigninAndToken_RegisteredDevice() async throws {
//        // Arrange
//        let signinHit = expectation(description: "/auth/local/signin")
//        let tokenHit = expectation(description: "/auth/token")
//        let finished = expectation(description: "login completion")
//        let success = expectation(description: "delegate success")
//        
//        // the mock must expose this closure
//        delegate.onAuthenticationSuccessful = {
//            success.fulfill()
//        }
//        
//        _ = Stubs.installJSONStub(
//            urlString: TestURLs.signinLocal,
//            file: "signinSuccess.json",
//            delegate: net,
//            onHit: { signinHit.fulfill() }
//        )
//        _ = Stubs.installJSONStub(
//            urlString: TestURLs.token,
//            file: "tokenSuccess.json",
//            delegate: net,
//            onHit: { tokenHit.fulfill() }
//        )
//
//        // Act
//        let s = try await server()
//        coordinator.start(s)
//        
//        coordinator.login(
//            withParameters: loginParams(),
//            withAuthenticationStrategy: "local") { _, _ in
//                finished.fulfill()
//            }
//        
//        // signin + token + login completion
//        await fulfillment(of: [signinHit, tokenHit, finished], timeout: 4.0)
//        
//        // unblock the coordinator so it can notify the delegate
//        coordinator.disclaimerAgree()
//        
//        // Assert
//        await fulfillment(of: [success], timeout: 1.0)
//    }
//    
//    // MARK: - Disclaimer variants
//    // TODO: BRENT - This may be identical to the one above
//    func test_Registered_ShowsDisclaimer_AndAgreeCallsDelegate() async throws {
//        // Arrange
//        let signinHit = expectation(description: "/auth/local/signin")
//        let tokenHit = expectation(description: "/auth/token")
//        let finished = expectation(description: "login completion")
//        let success = expectation(description: "delegate success")
//        
//        // the mock must expose this closure
//        delegate.onAuthenticationSuccessful = {
//            success.fulfill()
//        }
//        
//        _ = MAGETests.Stubs.installJSONStub(
//            urlString: TestURLs.signinLocal,
//            file: "signinSuccess.json",
//            delegate: net,
//            onHit: { signinHit.fulfill() }
//        )
//        _ = MAGETests.Stubs.installJSONStub(
//            urlString: TestURLs.token,
//            file: "tokenSuccess.json",
//            delegate: net,
//            onHit: { tokenHit.fulfill() }
//        )
//
//        // Act
//        let s = try await server()
//        coordinator.start(s)
//        
//        coordinator.login(
//            withParameters: loginParams(),
//            withAuthenticationStrategy: "local") { _, _ in
//                finished.fulfill()
//            }
//        
//        // signin + token + login completion
//        await fulfillment(of: [signinHit, tokenHit, finished], timeout: 4.0)
//        
//        // unblock the coordinator so it can notify the delegate
//        coordinator.disclaimerAgree()
//        
//        // Assert
//        await fulfillment(of: [success], timeout: 1.0)
//    }
//    
//    func test_Registered_ShowsDisclaimer_AgreeCallsDelegate() async throws {
//        UserDefaults.standard.set(true, forKey: "showDisclaimer")
//
//        let signinHit = expectation(description: "/auth/local/signin")
//        let tokenHit  = expectation(description: "/auth/token")
//        let finished  = expectation(description: "login completion")
//        let success   = expectation(description: "delegate success")
//
//        // wire mock delegate callback
//        delegate.onAuthenticationSuccessful = { success.fulfill() }
//
//        _ = Stubs.installJSONStub(urlString: TestURLs.signinLocal,
//                                  file: "signinSuccess.json",
//                                  delegate: net, onHit: { signinHit.fulfill() })
//        _ = Stubs.installJSONStub(urlString: TestURLs.token,
//                                  file: "tokenSuccess.json",
//                                  delegate: net, onHit: { tokenHit.fulfill() })
//
//        let s = try await server()
//        coordinator.start(s)
//
//        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in
//            finished.fulfill()
//        }
//
//        await fulfillment(of: [signinHit, tokenHit, finished], timeout: 4.0)
//
//        await MainActor.run { self.coordinator.disclaimerAgree() }
//
//        await fulfillment(of: [success], timeout: 2.0)
//    }
//
//    
//    func test_Registered_ShowsDisclaimer_DisagreeTriggersLogout() async throws {
//        // Ensure this path actually shows the disclaimer
//        UserDefaults.standard.set(true, forKey: "showDisclaimer")
//        
//        let signinHit = expectation(description: "/auth/local/signin")
//        let tokenHit = expectation(description: "/auth/token")
//        let finished = expectation(description: "login completion")
//        
//        _ = MAGETests.Stubs.installJSONStub(
//            urlString: TestURLs.signinLocal,
//            file: "signinSuccess.json",
//            delegate: net,
//            onHit: { signinHit.fulfill() }
//        )
//        _ = MAGETests.Stubs.installJSONStub(
//            urlString: TestURLs.token,
//            file: "tokenSuccess.json",
//            delegate: net,
//            onHit: { tokenHit.fulfill() }
//        )
//
//        let s = try await server()
//        coordinator.start(s)
//        
//        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in
//            finished.fulfill()
//        }
//        
//        // wait until login finished and both requests fired (we're at the disclaimer)
//        await fulfillment(of: [signinHit, tokenHit, finished], timeout: 4.0)
//        
//        // Assert logout by watching the app TestingAppDelegate flag
//        let appDelegate = UIApplication.shared.delegate as! TestingAppDelegate
//        appDelegate.logoutCalled = false // reset just in case
//
//        let loggedOut = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in appDelegate.logoutCalled }, object: nil)
//        
//        await MainActor.run { self.coordinator.disclaimerDisagree() }
//        
//        await fulfillment(of: [loggedOut], timeout: 3.0)
//    }
//    
////    // MARK: - Different user with unsaved observations
////    func test_DifferentUser_WithUnsavedData_ContinueClearsAndProceeds() async throws {
////        _ = MageCoreDataFixtures.addUser()
////        MageCoreDataFixtures.addUnsyncedObservationToEvent()
////        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1))
////        
////        Stubs.authSuccess(delegate: net)
////        
////        let s = try await server()
////        coordinator.start(s)
////        
////        // Login as a different username
////        let params = loginParams(username: "different", password: "password")
////        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { _, _ in }
////        
////        // Simulate tapping "Continue" from the alert:
////        // Clear data then call the same method the alert invokes.
////        MageInitializer.clearServerSpecificData()
////        if let localModule = s.authenticationModules?["local"] as? AuthenticationProtocol {
////            coordinator.authenticationWasSuccessful(withModule: localModule)
////        }
////        
////        waitForURLs([URL(string: TestURLs.signinLocal)!, URL(string: TestURLs.token)!])
////        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0))
////        expect(self.delegate.authenticationSuccessfulCalled).toEventually(beTrue())
////    }
////    
////    func test_DifferentUser_WithUnsavedData_CancelKeepsData() async throws {
////        _ = MageCoreDataFixtures.addUser()
////        MageCoreDataFixtures.addUnsyncedObservationToEvent()
////        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1))
////        
////        Stubs.authSuccess(delegate: net)
////        
////        let s = try await server()
////        coordinator.start(s)
////        
////        // Attempt to login as different user, but do NOT simulate "Continue"
////        let params = loginParams(username: "different", password: "password")
////        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { _, _ in }
////        
////        waitForURLs([URL(string: TestURLs.signinLocal)!, URL(string: TestURLs.token)!])
////        
////        let noSuccess = expectation(description: "no auth success")
////        noSuccess.isInverted = true
////        
//////        delegate.authenticationSuccessfulCalled = true
////        
////        // _trigger the login attempt_
////        await fulfillment(of: [noSuccess], timeout: 0.3)
////        XCTAssertEqual(MageOfflineObservationManager.offlineObservationCount(), 1)
////        XCTAssertFalse(delegate.authenticationSuccessfulCalled)
////    }
////    
////    // MARK: - Inactive user / registration
////    func test_InactiveUser_ShowsAccountCreatedAlert() async throws {
////        Stubs.authSigninSuccessOnly(signinFixture: "signinSuccessInactiveUser.json", delegate: net)
////        
////        let s = try await server()
////        coordinator.start(s)
////        
////        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in }
////        
////        // Only signin is stubbed here by design
////        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signinLocal)!))
////        
////        // Verify the specific alert from account creation path
////        expect(self.topAlertTitle()).toEventually(equal("MAGE Account Created"))
////    }
//    
//    // MARK: - Token failure
//    func test_TokenFailure_ShowsLoginFailedInfo() async throws {
//        // Expect the 2 network hits
//        let signinHit = expectation(description: "/auth/local/signin")
//        let tokenHit = expectation(description: "/auth/token (401)")
//        
//        _ = Stubs.installJSONStub(
//            urlString: TestURLs.signinLocal,
//            file: "signinSuccess.json",
//            delegate: net,
//            onHit: { signinHit.fulfill() }
//        )
//        
//        // Fail token call with JSON so AFNetworking treats it as such
//        let tokenURL = URL(string: TestURLs.token)!
//        HTTPStubs.stubRequests(passingTest: { req in
//            guard let url = req.url else { return false }
//            return url.host == tokenURL.host && _pathsMatch(url.path, tokenURL.path)
//        }) { req in
//            self.net.urlCalled(req.url, method: req.httpMethod)
//            tokenHit.fulfill()
//            
//            let body = try! JSONSerialization.data(
//                withJSONObject: ["message": "Failed to get a token"],
//                options: []
//            )
//            return HTTPStubsResponse(
//                data: body,
//                statusCode: 401,
//                headers: ["Content-Type": "application/json"]
//            ).responseTime(0.01)
//        }
//        
//        // Start the flow
//        let s = try await server()
//        coordinator.start(s)
//        
//        let finished = expectation(description: "login completion")
//        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in
//            finished.fulfill()
//        }
//
//        // wait until network + completions are done
//        await fulfillment(of: [signinHit, tokenHit, finished], timeout: 4.0)
//        
//        // Assert delegate was NOT called (use inverted XCTest exp OR just XCTAssert)
//        let notCalled = expectation(description: "delegate not called")
//        notCalled.isInverted = true
//        // (If you have the closure on your mock, wire it here)
//        // delegate.onAuthSuccess = { notCalled.fulfill() }
//        await fulfillment(of: [notCalled], timeout: 0.5)
//        
//        // Or, if you mock exposes the flag
//        XCTAssertFalse(delegate.authenticationSuccessfulCalled)
//    }
//    
//    // MARK: - Offline Flows
////    func test_Offline_NoStoredPassword_ShowsUnableToLoginAlert() async throws {
////        // Clear any possible cached credentials
////        UserDefaults.standard.removeObject(forKey: "LoginParameters")
////        UserDefaults.standard.removeObject(forKey: "LoginType")
////        
////        // 1) Stub /auth/local/signin to fail with "not connected"
////        let notConnected = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
////        let signinURL = URL(string: TestURLs.signinLocal)!
////        let signinHit = expectation(description: "/usth/local/signin (offline)")
////        
////        HTTPStubs.stubRequests(passingTest: { req in
////            guard let url = req.url else { return false }
////            return url.host == signinURL.host && _pathsMatch(url.path, signinURL.path)
////        }) { req in
////            self.net.urlCalled(req.url, method: req.httpMethod)
////            signinHit.fulfill()
////            return HTTPStubsResponse(error: notConnected).responseTime(0.01)
////        }
////        
////        // 2) Start coordinator and wait until /api preload finished (start() done)
////        let apiHit = XCTNSPredicateExpectation(
////            predicate: NSPredicate { _, _ in self.net.urls.contains(URL(string: TestURLs.api)!) },
////            object: nil
////        )
////        
////        let s = try await server()
////        coordinator.start(s)
////        await fulfillment(of: [apiHit], timeout: 2.0)
////
////        // 3) Make sure the nav is actually on screen (don't require a specific VC)
////        let navVisible = XCTNSPredicateExpectation(
////            predicate: NSPredicate { _, _ in self.nav.viewIfLoaded?.window != nil },
////            object: nil
////        )
////        await fulfillment(of: [navVisible], timeout: 1.0)
////
////        // 4) Trigger login on the main actor
////        await MainActor.run {
////            self.coordinator.login(withParameters: self.loginParams(),
////                                   withAuthenticationStrategy: "local") { _, _ in }
////        }
////        
////        // 5) Network error happened
////        await fulfillment(of: [signinHit], timeout: 2.0)
////
////        // 6) Assert the alert. Look at nav.presented or the top VC's presented.
////        expect({
////            let presented = self.nav.presentedViewController ?? self.nav.topViewController?.presentedViewController
////            return (presented as? UIAlertController)?.title
////        })
////        .toEventually(equal("Unable to Login"), timeout: .seconds(2), pollInterval: .milliseconds(50))
////    }
//    
////    func test_Offline_WithStoredPassword_WorkOfflinePathCallsDelegate() async throws {
////        // Store creds so "Work Offline" branch is available
////        UserDefaults.standard.loginParameters = ["serverUrl": TestURLs.base, "username": "username"]
////        StoredPassword.persistPassword(toKeyChain: "password")
////        UserDefaults.standard.set(false, forKey: "showDisclaimer") // auto-skip disclaimer
////        
////        let notConnected = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
////        _ = Stubs.signinError(notConnected, delegate: net)
////        
////        let s = try await server()
////        coordinator.start(s)
////        
////        // Normally an alert shows and OK-workOffline. call it directly to avoid UI tapping:
////        coordinator.workOffline(loginParams(), complete: { _, _ in })
////        
////        expect(self.delegate.authenticationSuccessfulCalled).toEventually(beTrue())
////    }
//    
////    func test_Offline_Again_WithStoredPassword_LoginTypeOffline_ShowsDisconnectedLogin() async throws {
////        // Simulate prior offline login
////        UserDefaults.standard.loginType = "offline"
////        UserDefaults.standard.loginParameters = ["serverUrl": TestURLs.base, "username": "username"]
////        StoredPassword.persistPassword(toKeyChain: "password")
////        
////        let notConnected = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
////        _ = Stubs.signinError(notConnected, delegate: net)
////        
////        let s = try await server()
////        coordinator.start(s)
////        
////        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in }
////        
////        expect(self.topAlertTitle()).toEventually(equal("Disconnected Login"))
////        // We don't invoke the alert's action here; this verifies the correct branch appears
////    }
//    
////    // MARK: - Signup flows
////    func test_Signup_Active_SucceedsAndReturnsToLogin() async throws {
////        Stubs.signupCaptcha(delegate: net)
////        Stubs.signupVerificationSuccess(
////            fixture: "signupSuccess.json",
////            jsonBody: [
////                "username": "username","password": "password","passwordconfirm": "password",
////                "displayName": "display","phone":"","email":"","captchaText":"captcha"
////            ],
////            delegate: net
////        )
////        
////        let s = try await server()
////        coordinator.start(s)
////        
////        // Drive coordinator APIs directly
////        coordinator.getCaptcha("username") { _ in }
////        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signups)!))
////        
////        let params: [String: Any] = [
////            "username": "username","password": "password","passwordconfirm": "password",
////            "displayName": "display","phone":"","email":"","captchaText":"captcha"
////        ]
////        coordinator.signup(withParameters: params) { _ in }
////        
////        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signupsVerify)!))
////        // After success, the coordinator pops back to login
////        expect(self.nav.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self))
////    }
//    
////    func test_Signup_Inactive_Succeeds_WithAwaitingApprovalMessage() async throws {
////        Stubs.signupCaptcha(delegate: net)
////        Stubs.signupVerificationSuccess(
////            fixture: "signupSuccessInactive.json",
////            jsonBody: [
////                "username": "username","password": "password","passwordconfirm": "password",
////                "displayName": "display","phone":"","email":"","captchaText":"captcha"
////            ], delegate: net
////        )
////        
////        let s = try await server()
////        coordinator.start(s)
////        
////        _ = await coordinator.getCaptcha("username")
////        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signups)!))
////        
////        coordinator.signup(withParameters: [
////            "username": "username","password": "password","passwordconfirm": "password",
////             "displayName": "display","phone":"","email":"","captchaText":"captcha"
////        ]) { _ in }
////        
////        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signupsVerify)!))
////        // An alert is presented; then we pop to login
////        expect(self.nav.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self))
////    }
////    
////    func test_Signup_Failure_ShowsErrorAlert_AndStaysOnSignup() async throws {
////        // Only the verification endpoint fials here
////        Stubs.signupVerificationFailure(status: 503, body: "error message", delegate: net)
////     
////        let s = try await server()
////        coordinator.start(s)
////        
////        // Enter signup and submit
////        coordinator.createAccount() // pushes SignUp VC
////        coordinator.signup(withParameters: [
////            "username": "username","password": "password","passwordconfirm": "password",
////             "displayName": "display","phone":"","email":"","captchaText":"captcha"
////        ]) { _ in }
////        
////    }
////    
//    
//    
    
}


