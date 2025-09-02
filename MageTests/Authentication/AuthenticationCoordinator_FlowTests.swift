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
    
    var nav: UINavigationController!
    var delegate: MockAuthenticationCoordinatorDelegate!
    var coordinator: AuthenticationCoordinator!
    var net: MockMageServerDelegate!
    
    // MARK: - Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Defaults common to many tests
        UserDefaults.standard.baseServerUrl = TestURLs.base
        UserDefaults.standard.deviceRegistered = true
        UserDefaults.standard.set(true, forKey: "showDisclaimer")  // opt-in; tests override when needed
        
        nav = UINavigationController()
        let win = TestHelpers.getKeyWindowVisible()
        win.rootViewController = nav
        win.makeKeyAndVisible()
        
        delegate = MockAuthenticationCoordinatorDelegate()
        coordinator = AuthenticationCoordinator(
            navigationController: nav,
            andDelegate: delegate,
            andScheme: MAGEScheme.scheme(),
            context: context
        )
        
        net = MockMageServerDelegate()
        Stubs.removeAll()
        
        HTTPStubs.onStubActivation { [weak self] request, _, response in
            guard let self, let url = request.url else { return }
            self.net?.urlCalled(url, method: request.httpMethod)
          print("[STUB] Matched \(url.absoluteString) -> \(response.statusCode)")
        }

        Stubs.api(delegate: net)    // /api and /apa/server
    }
    
    override func tearDown() async throws {
        // 1) Remove stubs first so nothing new starts
        Stubs.removeAll()
        
        // 2) Cancel any in-flight requests and let them finish canceling
        let session = MageSessionManager.shared().session
        await session.cancelAllTasksAndWaitASmidge()

        // 3) Now it's safe to invalidate & clean up
        session.invalidateAndCancel()
        
        coordinator = nil
        delegate = nil
        nav = nil
        UserDefaults.standard.clearAll()
        
        try await super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func server() async throws -> MageServer {
        let url = URL(string: TestURLs.base)!
        return try await withCheckedThrowingContinuation { (c: CheckedContinuation<MageServer, Error>) in
            MageServer.server(url: url, success: { server in
                c.resume(returning: server)
            }, failure: { error in
                c.resume(throwing: error)
            })
        }
    }
    
    private func loginParams(
        username: String = "username",
        password: String = "password"
    ) -> [AnyHashable: Any] {
        return [
            "username": username,
            "password": password,
            "uid": "uuid",
            "strategy": ["identifier": "local"],
            "appVersion": (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
        ]
    }
    
    private func waitForURLs(_ urls: [URL], timeout: TimeInterval = 2) {
        for u in urls {
            expect(self.net.urls).toEventually(contain(u), timeout: .seconds(Int(timeout)), pollInterval: .milliseconds(100))
        }
    }
    
    private func topAlertTitle(timeout: TimeInterval = 2) -> String? {
        var title: String?
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let alert = nav.presentedViewController as? UIAlertController {
                title = alert.title
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return title
    }
    
    private func startWithAuthSuccess() async throws {
        Stubs.authSuccess(delegate: net)
        let s = try await server()
        coordinator.start(s)
    }
    
    
    
    func test_Start_HitsAPI() async throws {
        // Arrange
        Stubs.removeAll()
        Stubs.api(delegate: net)
        
        // Act
        let s = try await server()
        coordinator.start(s)
        
        // Assert
        expect(self.net.urls).toEventually(
            contain(URL(string: TestURLs.api)!),
            timeout: .seconds(4), pollInterval: .milliseconds(50)
        )
    }
    
    
    // MARK: - Core: local login makes signin + token
    
    func test_LocalLogin_HitsSigninAndToken_RegisteredDevice() async throws {
        // Skip disclaimer to directly call delegate on success
        UserDefaults.standard.set(false, forKey: "showDisclaimer")
        
        try await startWithAuthSuccess() // installs stubs + server + coordinator.start

        let done = expectation(description: "login finished")
        coordinator.login(
            withParameters: loginParams(),
            withAuthenticationStrategy: "local"
        ) { _, _ in
            done.fulfill()  // ServerAuthentication.login completion fires after token handling
        }
        
        // Also keep the url assertions, but with a larger timeout
        expect(self.net.urls).toEventually(
            contain(URL(string: TestURLs.signinLocal)!),
            timeout: .seconds(8),
            pollInterval: .milliseconds(50)
        )
        expect(self.net.urls).toEventually(
            contain(URL(string: TestURLs.token)!),
            timeout: .seconds(8),
            pollInterval: .milliseconds(50)
        )

        //        waitForURLs([URL(string: TestURLs.signinLocal)!, URL(string: TestURLs.token)!])
        // Wait for the login completion so we know callbacks are done
        wait(for: [done], timeout: 8)
        
        // And the coordinator behavior:
        expect(self.delegate.authenticationSuccessfulCalled)
            .toEventually(beTrue(), timeout: .seconds(2))
    }
    
    // MARK: - Disclaimer variants
    
    func test_Registered_ShowsDisclaimer_AndAgreeCallsDelegate() async throws {
        // showDisclaimer already true in setUp
        Stubs.authSuccess(delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        coordinator.login(
            withParameters: loginParams(),
            withAuthenticationStrategy: "local"
        ) { _, _ in }
        
        waitForURLs([URL(string: TestURLs.signinLocal)!, URL(string: TestURLs.token)!])
        
        // Simulate user tapping "AGREE"
        coordinator.disclaimerAgree()
        
        expect(self.delegate.authenticationSuccessfulCalled).toEventually(beTrue())
    }
    
    func test_Registered_ShowsDisclaimer_DisagreeTriggersLogout() async throws {
        Stubs.authSuccess(delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in }
        
        waitForURLs([URL(string: TestURLs.signinLocal)!, URL(string: TestURLs.token)!])
        
        coordinator.disclaimerDisagree()
        
        // Same assertion our KIF test used...
        let appDelegate = UIApplication.shared.delegate as! TestingAppDelegate
        expect(appDelegate.logoutCalled).toEventually(beTrue())
    }
    
    // MARK: - Different user with unsaved observations
    func test_DifferentUser_WithUnsavedData_ContinueClearsAndProceeds() async throws {
        _ = MageCoreDataFixtures.addUser()
        MageCoreDataFixtures.addUnsyncedObservationToEvent()
        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1))
        
        Stubs.authSuccess(delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        // Login as a different username
        let params = loginParams(username: "different", password: "password")
        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { _, _ in }
        
        // Simulate tapping "Continue" from the alert:
        // Clear data then call the same method the alert invokes.
        MageInitializer.clearServerSpecificData()
        if let localModule = s.authenticationModules?["local"] as? AuthenticationProtocol {
            coordinator.authenticationWasSuccessful(withModule: localModule)
        }
        
        waitForURLs([URL(string: TestURLs.signinLocal)!, URL(string: TestURLs.token)!])
        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(0))
        expect(self.delegate.authenticationSuccessfulCalled).toEventually(beTrue())
    }
    
    func test_DifferentUser_WithUnsavedData_CancelKeepsData() async throws {
        _ = MageCoreDataFixtures.addUser()
        MageCoreDataFixtures.addUnsyncedObservationToEvent()
        expect(MageOfflineObservationManager.offlineObservationCount()).to(equal(1))
        
        Stubs.authSuccess(delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        // Attempt to login as different user, but do NOT simulate "Continue"
        let params = loginParams(username: "different", password: "password")
        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { _, _ in }
        
        waitForURLs([URL(string: TestURLs.signinLocal)!, URL(string: TestURLs.token)!])
        
        let noSuccess = expectation(description: "no auth success")
        noSuccess.isInverted = true
        
//        delegate.authenticationSuccessfulCalled = true
        
        // _trigger the login attempt_
        await fulfillment(of: [noSuccess], timeout: 0.3)
        XCTAssertEqual(MageOfflineObservationManager.offlineObservationCount(), 1)
        XCTAssertFalse(delegate.authenticationSuccessfulCalled)
    }
    
    // MARK: - Inactive user / registration
    func test_InactiveUser_ShowsAccountCreatedAlert() async throws {
        Stubs.authSigninSuccessOnly(signinFixture: "signinSuccessInactiveUser.json", delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in }
        
        // Only signin is stubbed here by design
        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signinLocal)!))
        
        // Verify the specific alert from account creation path
        expect(self.topAlertTitle()).toEventually(equal("MAGE Account Created"))
    }
    
    // MARK: - Token failure
    func test_TokenFailure_ShowsLoginFailedInfo() async throws {
        Stubs.authSigninSuccessOnly(delegate: net)
        Stubs.tokenFailure(status: 401, body: "Failed to get a token", delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in }
        
        waitForURLs([URL(string: TestURLs.signinLocal)!, URL(string: TestURLs.token)!])
        
        // The coordinator writes ContactInfo to the login VC; at least ensure no success callback:
        expect(self.delegate.authenticationSuccessfulCalled).toEventually(beFalse())
    }
    
    // MARK: - Offline Flows
    func test_Offline_NoStoredPassword_ShowsUnableToLoginAlert() async throws {
        // No stored password / loginParameters
        let notConnected = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        _ = Stubs.signinError(notConnected, delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in }
        
        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signinLocal)!))
        expect(self.topAlertTitle()).toEventually(equal("Unable to Login"))
    }
    
    func test_Offline_WithStoredPassword_WorkOfflinePathCallsDelegate() async throws {
        // Store creds so "Work Offline" branch is available
        UserDefaults.standard.loginParameters = ["serverUrl": TestURLs.base, "username": "username"]
        StoredPassword.persistPassword(toKeyChain: "password")
        UserDefaults.standard.set(false, forKey: "showDisclaimer") // auto-skip disclaimer
        
        let notConnected = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        _ = Stubs.signinError(notConnected, delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        // Normally an alert shows and OK-workOffline. call it directly to avoid UI tapping:
        coordinator.workOffline(loginParams(), complete: { _, _ in })
        
        expect(self.delegate.authenticationSuccessfulCalled).toEventually(beTrue())
    }
    
    func test_Offline_Again_WithStoredPassword_LoginTypeOffline_ShowsDisconnectedLogin() async throws {
        // Simulate prior offline login
        UserDefaults.standard.loginType = "offline"
        UserDefaults.standard.loginParameters = ["serverUrl": TestURLs.base, "username": "username"]
        StoredPassword.persistPassword(toKeyChain: "password")
        
        let notConnected = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        _ = Stubs.signinError(notConnected, delegate: net)
        
        let s = try await server()
        coordinator.start(s)
        
        coordinator.login(withParameters: loginParams(), withAuthenticationStrategy: "local") { _, _ in }
        
        expect(self.topAlertTitle()).toEventually(equal("Disconnected Login"))
        // We don't invoke the alert's action here; this verifies the correct branch appears
    }
    
    // MARK: - Signup flows
    func test_Signup_Active_SucceedsAndReturnsToLogin() async throws {
        Stubs.signupCaptcha(delegate: net)
        Stubs.signupVerificationSuccess(
            fixture: "signupSuccess.json",
            jsonBody: [
                "username": "username","password": "password","passwordconfirm": "password",
                "displayName": "display","phone":"","email":"","captchaText":"captcha"
            ],
            delegate: net
        )
        
        let s = try await server()
        coordinator.start(s)
        
        // Drive coordinator APIs directly
        coordinator.getCaptcha("username") { _ in }
        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signups)!))
        
        let params: [String: Any] = [
            "username": "username","password": "password","passwordconfirm": "password",
            "displayName": "display","phone":"","email":"","captchaText":"captcha"
        ]
        coordinator.signup(withParameters: params) { _ in }
        
        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signupsVerify)!))
        // After success, the coordinator pops back to login
        expect(self.nav.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self))
    }
    
//    func test_Signup_Inactive_Succeeds_WithAwaitingApprovalMessage() async throws {
//        Stubs.signupCaptcha(delegate: net)
//        Stubs.signupVerificationSuccess(
//            fixture: "signupSuccessInactive.json",
//            jsonBody: [
//                "username": "username","password": "password","passwordconfirm": "password",
//                "displayName": "display","phone":"","email":"","captchaText":"captcha"
//            ], delegate: net
//        )
//        
//        let s = try await server()
//        coordinator.start(s)
//        
//        _ = await coordinator.getCaptcha("username")
//        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signups)!))
//        
//        coordinator.signup(withParameters: [
//            "username": "username","password": "password","passwordconfirm": "password",
//             "displayName": "display","phone":"","email":"","captchaText":"captcha"
//        ]) { _ in }
//        
//        expect(self.net.urls).toEventually(contain(URL(string: TestURLs.signupsVerify)!))
//        // An alert is presented; then we pop to login
//        expect(self.nav.topViewController).toEventually(beAnInstanceOf(LoginHostViewController.self))
//    }
//    
//    func test_Signup_Failure_ShowsErrorAlert_AndStaysOnSignup() async throws {
//        // Only the verification endpoint fials here
//        Stubs.signupVerificationFailure(status: 503, body: "error message", delegate: net)
//     
//        let s = try await server()
//        coordinator.start(s)
//        
//        // Enter signup and submit
//        coordinator.createAccount() // pushes SignUp VC
//        coordinator.signup(withParameters: [
//            "username": "username","password": "password","passwordconfirm": "password",
//             "displayName": "display","phone":"","email":"","captchaText":"captcha"
//        ]) { _ in }
//        
//    }
//    
    
    
    
}


