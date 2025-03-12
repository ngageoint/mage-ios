//
//  AuthenticationTests.m
//  MAGETests
//
//  Created by Dan Barela on 1/9/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import OHHTTPStubs

@testable import MAGE

// Starting from server responses and working backward
protocol AuthenticationServiceProtocol {
    func signIn(username: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void)
    func fetchAuthToken(uid: String, completion: @escaping (Result<TokenResponse, Error>) -> Void)
}

struct AuthResponse: Codable {
    let token: String
    let userId: String
}

struct TokenResponse: Codable {
    let accessToken: String
}







// Starting from server responses and working backward



class AuthenticationTestDelegate: AuthenticationDelegate {
    var authenticationSuccessfulCalled = false
    var couldNotAuthenticateCalled = false
    var changeServerUrlCalled = false
    
    func authenticationSuccessful() {
        authenticationSuccessfulCalled = true
    }
    
    func couldNotAuthenticate() {
        couldNotAuthenticateCalled = true
    }
    
    func changeServerUrl() {
        changeServerUrlCalled = true
    }
}

final class AuthenticationTests: AsyncMageCoreDataTestCase {
    
    var window: UIWindow!
    var navigationController: UINavigationController!
    var delegate: AuthenticationTestDelegate!
    var coordinator: AuthenticationCoordinator!
    
    private var apiExpectations: [String: XCTestExpectation] = [:]
    private var stubFulfillmentHandlers: [String: (() -> Void)] = [:]
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        setUpAuthenticationTestEnvironment()
        
        // Store fulfillment handlers for each API endpoint
        stubFulfillmentHandlers = [
            "/api": { self.apiExpectations["/api"]?.fulfill() },
            "/auth/local/signin": { self.apiExpectations["/auth/local/signin"]?.fulfill() },
            "/auth/token": { self.apiExpectations["/auth/token"]?.fulfill() }
        ]
    }
    
    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        window.rootViewController = nil;
    }
    
    private func configureAuthenticationEnvironment() {
        MageSessionManager.shared()?.setToken("TOKEN")
        StoredPassword.persistToken(toKeyChain: "TOKEN")
    }

    private func configureUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: "baseServerUrl")
        defaults.set(true, forKey: "deviceRegistered")
    }
    
    private func setUpAuthenticationTestEnvironment() {
        window = TestHelpers.getKeyWindowVisible()
        navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        delegate = AuthenticationTestDelegate()
        UserDefaults.standard.baseServerUrl = "https://magetest"
        UserDefaults.standard.register(defaults: ["deviceRegistered": true])
        MageSessionManager.shared()?.clearToken()

        coordinator = AuthenticationCoordinator(
            navigationController: navigationController,
            andDelegate: delegate,
            andScheme: MAGEScheme.scheme(),
            context: context)
    }
    
    /// 🔥 Creates expectations for API calls and assigns fulfillment handlers
    private func createAPIExpectations() -> ([String: XCTestExpectation], [String: () -> Void]) {
        var apiExpectations: [String: XCTestExpectation] = [:]
        var stubFulfillmentHandlers: [String: () -> Void] = [:]

        let endpoints = ["/api", "/auth/local/signin", "/auth/token"]

        for endpoint in endpoints {
            let expectation = XCTestExpectation(description: "response of \(endpoint) complete")
            apiExpectations[endpoint] = expectation
            stubFulfillmentHandlers[endpoint] = { expectation.fulfill() }
        }
        
        return (apiExpectations, stubFulfillmentHandlers)
    }
    
    /// 🔥 Stub all required API responses for authentication tests
    private func stubAPIResponses(with fulfillmentHandlers: [String: () -> Void]) {
        stub(condition: isMethodGET() && isHost("magetest") && isPath("/api")) { _ in
            print("\nFulfilled stubbed: /api\n")
            fulfillmentHandlers["/api"]?()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!,
                                     statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        stub(condition: isMethodPOST() && isPath("/auth/local/signin")) { _ in
            print("\nFulfilled stubbed: /auth/local/signin\n")
            fulfillmentHandlers["/auth/local/signin"]?()  // Call the fulfillment closure
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!,
                                     statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        // 🔥 Added: Token authentication stub
        stub(condition: isMethodPOST() && isPath("/auth/token")) { _ in
            print("\nFulfilled stubbed: /auth/token\n")
            fulfillmentHandlers["/auth/token"]?()  // Call the fulfillment closure
            return HTTPStubsResponse(fileAtPath: OHPathForFile("authorizeLocalSuccess.json", AuthenticationTests.self)!,
                                     statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        // 🔥 Added: User icon stub
        stub(condition: isMethodPOST() && isPath("/api/users/1a/icon")) { _ in
            print("Fulfilled stubbed: /api/users/1a/icon")
            self.apiExpectations["/api/users/1a/icon"]?.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("icon27.png", AuthenticationTests.self)!,
                                     statusCode: 200, headers: ["Content-Type": "image/png"])
        }

        // 🔥 Added: User avatar stub
        stub(condition: isMethodPOST() && isPath("/api/users/1a/avatar")) { _ in
            print("Fulfilled stubbed: /api/users/1a/avatar")
            self.apiExpectations["/api/users/1a/avatar"]?.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("icon27.png", AuthenticationTests.self)!,
                                     statusCode: 200, headers: ["Content-Type": "image/png"])
        }
        
    }

//    /// 🚀 Helper function to create a MageServer instance
//    private func createTestServer() async -> MageServer {
//        let url = MageServer.baseURL()
//        return await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { server in
//                continuation.resume(returning: server)
//            } failure: { _ in
//                XCTFail("❌ Failed to create MageServer instance")
//            }
//        }
//    }
    
//    /// 🚀 Helper function to verify login screen appears
//    @MainActor
//    private func verifyLoginScreenAppeared() async {
//        await awaitBlockTrue(block: { [weak self] in  // ✅ Weak capture of `self`
//            guard let self = self else { return false }
//            guard let topVC = self.navigationController?.topViewController else {
//                XCTFail("❌ No top view controller in navigation stack!")
//                return false
//            }
//            if !(topVC is LoginViewController) {
//                XCTFail("❌ Expected LoginViewController, but found \(type(of: topVC))")
//                return false
//            }
//            return true
//        }, timeout: 2)
//    }
    
//    /// 🚀 Helper function to perform a login
//    @MainActor
//    private func performLogin(username: String, password: String) -> Bool {
//        let parameters: [String: Any] = [
//            "username": username,
//            "password": password,
//            "uid": "uuid",
//            "strategy": ["identifier": "local"],
//            "appVersion": "6.0.0"
//        ]
//        
//        var authenticationStatus: AuthenticationStatus?
//        
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { status, _ in
//            authenticationStatus = status
//        }
//        
//        return authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS
//    }

//    @MainActor
//    private func verifyNavigationStackContains(_ expectedViewController: AnyClass, timeout: TimeInterval = 2) async {
//        await awaitBlockTrue(block: { [weak self] in
//            guard let self = self else { return false }
//            guard let navigationController = self.navigationController else {
//                XCTFail("❌ navigationController is nil before checking the navigation stack!")
//                return false
//            }
//
//            // ✅ Check if any view controller in the stack matches
//            let containsExpectedVC = navigationController.viewControllers.contains { $0.isKind(of: expectedViewController) }
//
//            if !containsExpectedVC {
//                print("⚠️ \(expectedViewController) not found in navigation stack.")
//                return false
//            }
//
//            return true
//        }, timeout: timeout)
//    }


    @MainActor
    private func verifyNavigationStackContains(_ expectedViewController: AnyClass, timeout: TimeInterval = 2) async {
        await awaitBlockTrue(block: { [weak self] in
            guard let self = self else { return false }
            guard let navigationController = self.navigationController else {
                XCTFail("❌ navigationController is nil before checking the navigation stack!")
                return false
            }

            print("📌 Navigation Stack Contains: \(navigationController.viewControllers)")

            let stack = navigationController.viewControllers.map { String(describing: type(of: $0)) }
            print("📌 Navigation Stack: \(stack)")

            let containsExpectedVC = navigationController.viewControllers.contains { $0.isKind(of: expectedViewController) }

            if !containsExpectedVC {
                XCTFail("❌ Expected \(expectedViewController), but got stack: \(stack)")
                return false
            }

            return true
        }, timeout: timeout)
    }

    
    @MainActor
    func testLoginWithRegisteredDeviceAndRandomTokenBrent() async {
        configureAuthenticationEnvironment()
        configureUserDefaults()

        // Create expectations dynamically
        (apiExpectations, stubFulfillmentHandlers) = createAPIExpectations()
        
        // Apply the stubs
        stubAPIResponses(with: stubFulfillmentHandlers)

        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { server in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail("❌ Failed to create MageServer")
            }
        }
        
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        coordinator = AuthenticationCoordinator(
            navigationController: navigationController,
            andDelegate: delegate,
            andScheme: MAGEScheme.scheme(),
            context: context
        )!

        // Ensure coordinator starts before checking the navigation stack
        Task {
            coordinator.start(server)
            try? await Task.sleep(nanoseconds: 500_000_000)  // ⏳ Wait for 0.5 sec
            await verifyNavigationStackContains(LoginViewController.self)
        }
            
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
        let loginDelegate = coordinator as! LoginDelegate
        print("🚀 Initiating login request...")
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            print("✅ Login response received! Status: \(authenticationStatus)")
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
            XCTAssertEqual(token, mageSessionToken)
        }
        
        await verifyNavigationStackContains(DisclaimerViewController.self, timeout: 4)
        
        let disclaimerDelegate = coordinator as! DisclaimerDelegate
        disclaimerDelegate.disclaimerAgree()
        
        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
        
        // Wait for API expectations to be fulfilled
        await fulfillment(of: apiExpectations.values.map { $0 }, timeout: 5)
    }

    

    @MainActor
    func testLoginWithRegisteredDeviceAndRandomTokenBrentZZZ() async {
        configureAuthenticationEnvironment()
        configureUserDefaults()

        // Create expectations dynamically
        let (apiExpectations, stubFulfillmentHandlers) = createAPIExpectations()
        
        // Apply the stubs
        stubAPIResponses(with: stubFulfillmentHandlers)

        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        
        Task {
            coordinator.start(server)
            await verifyNavigationStackContains(LoginViewController.self)
        }
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
            XCTAssertEqual(token, mageSessionToken)
        }
        
        await verifyNavigationStackContains(DisclaimerViewController.self)
        
        let disclaimerDelegate = coordinator as! DisclaimerDelegate
        disclaimerDelegate.disclaimerAgree()
        
        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
        
        // Wait for API expectations to be fulfilled
        await fulfillment(of: apiExpectations.values.map { $0 }, timeout: 5)
    }

    
    
//    @MainActor
//    func testLoginWithRegisteredDeviceAndRandomToken() async {
//        // 🎯 Configure the authentication & user defaults
//        configureAuthenticationEnvironment()
//        configureUserDefaults()
//
//        // 🎯 Step 1: Verify Login Screen Appeared
//        await verifyLoginScreenAppeared()
//
//        // 🎯 Step 2: Perform Login
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        let loginSuccess = performLogin(username: "test", password: "test")
//        XCTAssertTrue(loginSuccess, "❌ Expected login to succeed")
//
//        // 🎯 Step 3: Verify Token Storage
//        let storedToken = StoredPassword.retrieveStoredToken()
//        let sessionToken = MageSessionManager.shared().getToken()
//        XCTAssertEqual(storedToken, "TOKEN", "❌ Stored token mismatch")
//        XCTAssertEqual(sessionToken, "TOKEN", "❌ Session token mismatch")
//
//        // 🎯 Step 4: Verify Navigation to Disclaimer Screen
//        await verifyNavigationStackContains(DisclaimerViewController.self)
//
//        // 🎯 Step 5: Agree to Disclaimer
//        let disclaimerDelegate = coordinator as! DisclaimerDelegate
//        disclaimerDelegate.disclaimerAgree()
//
//        // 🎯 Step 6: Verify Authentication Delegate Callback
//        XCTAssertTrue(delegate.authenticationSuccessfulCalled, "❌ Expected authentication success callback")
//
//        // 🎯 Ensure API stubs were triggered
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//    }
    
    
    @MainActor
    func testLoginWithRegisteredDeviceAndRandomToken_original() async {
        let baseUrlKey = "baseServerUrl"
        MageSessionManager.shared()?.setToken("TOKEN")
        StoredPassword.persistToken(toKeyChain: "TOKEN")
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("authorizeLocalSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/api/users/1a/icon")
        ) { (request) -> HTTPStubsResponse in
            return HTTPStubsResponse(fileAtPath: OHPathForFile("icon27.png", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "image/png"])
        }
        
        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/api/users/1a/avatar")
        ) { (request) -> HTTPStubsResponse in
            return HTTPStubsResponse(fileAtPath: OHPathForFile("icon27.png", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "image/png"])
        }
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? DisclaimerViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let disclaimerDelegate = coordinator as! DisclaimerDelegate
        disclaimerDelegate.disclaimerAgree()
        
        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
        
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
    }
    
    @MainActor
    func testRegisterDevice() async {
        let baseUrlKey = "baseServerUrl"
        MageSessionManager.shared()?.setToken("TOKEN")
        StoredPassword.persistToken(toKeyChain: "TOKEN")
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            let response = HTTPStubsResponse()
            response.statusCode = 403
            return response
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        let deviceRegistered = XCTestExpectation(description: "device registered")
        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.REGISTRATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
            XCTAssertEqual(token, mageSessionToken)
            deviceRegistered.fulfill()
        }
        
        await fulfillment(of: [deviceRegistered], timeout: 2)
        tester().waitForView(withAccessibilityLabel: "Registration Sent")
    }
    
    @MainActor
    func testLoginWithRegisteredDevice() async {
        let baseUrlKey = "baseServerUrl"
        MageSessionManager.shared()?.setToken("TOKEN")
        StoredPassword.persistToken(toKeyChain: "TOKEN")
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("authorizeLocalSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
//        let deviceRegistered = XCTestExpectation(description: "device registered")

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? DisclaimerViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("disclaimer title").view != nil &&
            self.viewTester().usingLabel("disclaimer text").view != nil
        }, timeout: 2)
        
        let disclaimerDelegate = coordinator as! DisclaimerDelegate
        disclaimerDelegate.disclaimerAgree()
        
        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
        
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
    }
    
    @MainActor
    func testLoginWithUpdatedUser() async {
        MageCoreDataFixtures.addUser(userId: "1a");
        
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("authorizeLocalSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: "1a")!
            XCTAssertEqual(user.name, "User ABC")
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
//        let deviceRegistered = XCTestExpectation(description: "device registered")

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? DisclaimerViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("disclaimer title").view != nil &&
            self.viewTester().usingLabel("disclaimer text").view != nil
        }, timeout: 2)
        
        let disclaimerDelegate = coordinator as! DisclaimerDelegate
        disclaimerDelegate.disclaimerAgree()
        
        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
        
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
        
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: "1a")!
            XCTAssertEqual(user.name, "Firstname Lastname")
        }
    }
    
    @MainActor
    func testLoginWithInactiveUser() async {
//        StoredPassword.clearToken()
        
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccessInactiveUser.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
//        let deviceRegistered = XCTestExpectation(description: "device registered")

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.ACCOUNT_CREATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("MAGE Account Created").view != nil
        }, timeout: 2)
                
        await fulfillment(of: [apiSigninResponseArrived], timeout: 2)
    }
    
    @MainActor
    func testLoginWithNoConnection() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
            return HTTPStubsResponse(error:notConnectedError)
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
//        let deviceRegistered = XCTestExpectation(description: "device registered")

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.ACCOUNT_CREATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Unable to Login").view != nil
        }, timeout: 2)
                
        await fulfillment(of: [apiSigninResponseArrived], timeout: 2)
    }
    
    @MainActor
    func testLoginFailed() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            let response = HTTPStubsResponse()
            response.statusCode = 304
            return response
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
//        let deviceRegistered = XCTestExpectation(description: "device registered")

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_ERROR)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Login Failed").view != nil
        }, timeout: 2)
                
        await fulfillment(of: [apiSigninResponseArrived], timeout: 2)
    }
    
    @MainActor
    func testLoginWithNoConnectionForToken() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
            return HTTPStubsResponse(error:notConnectedError)
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
//        let deviceRegistered = XCTestExpectation(description: "device registered")

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Unable to Login").view != nil
        }, timeout: 2)
       
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
    }
    
    @MainActor
    func testLoginServerIncompatible() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "expirationDate":"2020-02-20T01:25:44.796Z",
                    "api":[
                        "name":"mage-server",
                        "description":"Geospatial situation awareness application.",
                        "version":[
                            "major":5,
                            "minor":0,
                            "micro":0
                        ],
                        "authenticationStrategies":[
                            "local":[
                                "passwordMinLength":14
                            ]
                        ],
                        "provision":[
                            "strategy":"uid"
                        ]
                    ]
                ],
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
//        let deviceRegistered = XCTestExpectation(description: "device registered")

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_ERROR)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Login Failed").view != nil
        }, timeout: 2)
       
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
    }
    
    @MainActor
    func testLoginWithOtherErrorForToken() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            let badServerResponse = NSError(domain: NSURLErrorDomain, code: URLError.badServerResponse.rawValue)
            return HTTPStubsResponse(error:badServerResponse)
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
//        let deviceRegistered = XCTestExpectation(description: "device registered")

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_ERROR)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Login Failed").view != nil
        }, timeout: 2)
       
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
    }
    
    @MainActor
    func testLoginFailWithRegisteredDevice() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(data: "Test".data(using: .utf8)!, statusCode: 401, headers: nil)
        }
        

        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_ERROR)
            let token = StoredPassword.retrieveStoredToken()
            XCTAssertEqual(token, "TOKEN")
        }
        
        await fulfillment(of: [apiSigninResponseArrived], timeout: 2)
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Login Failed").view != nil
        }, timeout: 2)
    }
    
    @MainActor
    func testLoginWithInvalidToken() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "expirationDate":"2020-02-20T01:25:44.796Z",
                    "api":[
                        "name":"mage-server",
                        "description":"Geospatial situation awareness application.",
                        "version":[
                            "major":6,
                            "minor":0,
                            "micro":0
                        ],
                        "authenticationStrategies":[
                            "local":[
                                "passwordMinLength":14
                            ]
                        ],
                        "provision":[
                            "strategy":"uid"
                        ]
                    ]
                ],
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            print("Authentication status \(authenticationStatus)")
            // TODO: This really should return AUTHENTICATION_ERROR but right now it returns success
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
        TestHelpers.printAllAccessibilityLabelsInWindows()
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Login Failed").view != nil &&
            self.viewTester().usingLabel("Copy Error Message Detail").view != nil
        }, timeout: 2)
    }
    
    @MainActor
    func testLoginWithInvalidTokenExpirationDate() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "token":"TOKEN",
                    "api":[
                        "name":"mage-server",
                        "description":"Geospatial situation awareness application.",
                        "version":[
                            "major":6,
                            "minor":0,
                            "micro":0
                        ],
                        "authenticationStrategies":[
                            "local":[
                                "passwordMinLength":14
                            ]
                        ],
                        "provision":[
                            "strategy":"uid"
                        ]
                    ]
                ],
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            print("Authentication status \(authenticationStatus)")
            // TODO: This really should return AUTHENTICATION_ERROR but right now it returns success
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
        TestHelpers.printAllAccessibilityLabelsInWindows()
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Login Failed").view != nil &&
            self.viewTester().usingLabel("Copy Error Message Detail").view != nil
        }, timeout: 2)
    }
    
    @MainActor
    func testLoginWithInvalidUsername() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "token":"TOKEN",
                    "expirationDate":"2020-02-20T01:25:44.796Z",
                    "api":[
                        "name":"mage-server",
                        "description":"Geospatial situation awareness application.",
                        "version":[
                            "major":6,
                            "minor":0,
                            "micro":0
                        ],
                        "authenticationStrategies":[
                            "local":[
                                "passwordMinLength":14
                            ]
                        ],
                        "provision":[
                            "strategy":"uid"
                        ]
                    ]
                ],
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
//            "username": "test",
            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            print("Authentication status \(authenticationStatus)")
            // TODO: This really should return AUTHENTICATION_ERROR but right now it returns success
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
        TestHelpers.printAllAccessibilityLabelsInWindows()
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Login Failed").view != nil &&
            self.viewTester().usingLabel("Copy Error Message Detail").view != nil
        }, timeout: 2)
    }
    
    @MainActor
    func testLoginWithInvalidPassword() async {
        let baseUrlKey = "baseServerUrl"
        
        let defaults = UserDefaults.standard
        defaults.set("https://magetest", forKey: baseUrlKey)
        defaults.set(true, forKey: "deviceRegistered")
        
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let delegate = AuthenticationTestDelegate()
        
        let url = MageServer.baseURL()
        
        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isPath("/api")
        ) { (request) -> HTTPStubsResponse in
            apiResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let server: MageServer = await withCheckedContinuation { continuation in
            MageServer.server(url: url) { (server: MageServer) in
                continuation.resume(returning: server)
            } failure: { error in
                XCTFail()
            }
        }
        XCTAssertEqual(url?.absoluteString, "https://magetest")
        
        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            apiSigninResponseArrived.fulfill()
            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")

        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isPath("/auth/token")
        ) { (request) -> HTTPStubsResponse in
            apiTokenStub.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "token":"TOKEN",
                    "expirationDate":"2020-02-20T01:25:44.796Z",
                    "api":[
                        "name":"mage-server",
                        "description":"Geospatial situation awareness application.",
                        "version":[
                            "major":6,
                            "minor":0,
                            "micro":0
                        ],
                        "authenticationStrategies":[
                            "local":[
                                "passwordMinLength":14
                            ]
                        ],
                        "provision":[
                            "strategy":"uid"
                        ],
                        "contactinfo": [
                            "email": "test@test.com",
                            "phone": "555-555-5555"
                        ]
                    ]
                ],
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
        
        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
        coordinator.start(server)
        
        await awaitBlockTrue(block: {
            if let _ = navigationController.topViewController as? LoginViewController {
                return true
            }
            return false
        }, timeout: 2)
        
        let parameters: [String: Any] = [
            "username": "test",
//            "password": "test",
            "uid": "uuid",
            "strategy": [
                "identifier": "local"
            ],
            "appVersion": "6.0.0"
        ]
        
        let loginDelegate = coordinator as! LoginDelegate
        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
            // login complete
            print("Authentication status \(authenticationStatus)")
            // TODO: This really should return AUTHENTICATION_ERROR but right now it returns success
            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
        }
        
        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
        TestHelpers.printAllAccessibilityLabelsInWindows()
        
        await awaitBlockTrue(block: {
            self.viewTester().usingLabel("Login Failed").view != nil &&
            self.viewTester().usingLabel("Copy Error Message Detail").view != nil
        }, timeout: 2)
        TestHelpers.printAllAccessibilityLabelsInWindows()
    }
}

//@import OHHTTPStubs;
//
//#import <XCTest/XCTest.h>
//#import <OCMock/OCMock.h>
//#import "AuthenticationCoordinator.h"
//#import "LoginViewController.h"
//#import "MageSessionManager.h"
//#import "StoredPassword.h"
//#import "Authentication.h"
//#import "MageOfflineObservationManager.h"
//#import "MagicalRecord+MAGE.h"
//#import "MAGE-Swift.h"
//
//@interface ServerURLController ()
//@property (strong, nonatomic) NSString *error;
//@end
//
//@interface AuthenticationCoordinator ()
//@property (strong, nonatomic) NSString *urlController;
//- (void) unableToAuthenticate: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
//- (void) workOffline: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
//- (void) returnToLogin:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
//- (void) changeServerURL;
//@end
//
//@interface AuthenticationTests : XCTestCase
//
//@end
//
//@interface AuthenticationTestDelegate : NSObject
//
//@end
//
//@interface AuthenticationTestDelegate() <AuthenticationDelegate>
//
//@end
//
//@implementation AuthenticationTestDelegate
//
//-(void) authenticationSuccessful {
//}
//
//@end
//
//@implementation AuthenticationTests
//
//- (void)setUp {
//    [super setUp];
//    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
//    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
//    [MagicalRecord setupCoreDataStackWithInMemoryStore];
//}
//
//- (void)tearDown {
//    [super tearDown];
//    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
//    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
//    [HTTPStubs removeAllStubs];
//}
//
//
//
//- (void) skipped_testLoginWithRegisteredDevice {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSLog(@"api request recieved and handled");
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    @"5.0.0", @"appVersion",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"loginSuccess.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//            [disclaimerDelegate disclaimerAgree];
//            OCMVerifyAll(delegatePartialMock);
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testLoginWithRegisteredDeviceChangingUserWithOfflineObservations {
//    User *u = [User MR_createEntity];
//    u.username = @"old";
//
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    id offlineManagerMock = OCMClassMock([MageOfflineObservationManager class]);
//    OCMStub(ClassMethod([offlineManagerMock offlineObservationCount]))._andReturn([NSNumber numberWithInt:1]);
//
//    id userMock = [OCMockObject mockForClass:[User class]];
//    [[[userMock stub] andReturn:u] fetchCurrentUserWithContext:[OCMArg any]];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    @"5.0.0", @"appVersion",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"signinSuccess.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            __unsafe_unretained UIAlertController *alert;
//            [invocation getArgument:&alert atIndex:2];
//            XCTAssertTrue([alert.title isEqualToString:@"Loss of Unsaved Data"]);
//            [loginResponseArrived fulfill];
//        });
//
//        OCMReject([navControllerPartialMock pushViewController:[OCMArg any] animated:[OCMArg any]]);
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testLoginWithRegisteredDeviceChangingUserWithoutOfflineObservations {
//    User *u = [User MR_createEntity];
//    u.username = @"old";
//
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"signinSuccess.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//            [disclaimerDelegate disclaimerAgree];
//            OCMVerifyAll(delegatePartialMock);
//        });
//
//        OCMReject([navControllerPartialMock pushViewController:[OCMArg any] animated:[OCMArg any]]);
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testLoginFailWithRegisteredDevice {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//    id delegatePartialMock = OCMPartialMock(delegate);
//    OCMExpect([delegatePartialMock authenticationSuccessful]);
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"test", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            HTTPStubsResponse *response = [[HTTPStubsResponse alloc] init];
//            response.statusCode = 401;
//
//            return response;
//        }];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api/devices"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSString* fixture = OHPathForFile(@"apiFail.json", self.class);
//            return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                    statusCode:401 headers:@{@"Content-Type":@"application/json"}];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//
//        OCMReject([navControllerPartialMock pushViewController:[OCMArg any] animated:[OCMArg any]]);
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            // login complete
////            XCTAssertTrue(authenticationStatus == AUTHENTICATION_ERROR);
////            [loginResponseArrived fulfill];
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//
//            OCMVerifyAll(navControllerPartialMock);
//        }];
//
//    }];
//}
//
//- (void) skipped_testWorkOffline {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", @"test", @"username", nil] forKey:@"loginParameters"];
//    [defaults setObject:[NSNumber numberWithDouble:2880] forKey:@"tokenExpirationLength"];
//    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
//    [[[storedPasswordMock stub] andReturn:@"goodpassword"] retrieveStoredPassword];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    __block AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        id<DisclaimerDelegate> disclaimerDelegate = (id<DisclaimerDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"goodpassword", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
//            return [HTTPStubsResponse responseWithError:notConnectedError];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//        id coordinatorMock = OCMPartialMock(coordinator);
//        OCMExpect([coordinatorMock unableToAuthenticate:[OCMArg any] complete:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
//        }).andForwardToRealObject();
//
////        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
////            __unsafe_unretained UIAlertController *alert;
////            [invocation getArgument:&alert atIndex:2];
////            XCTAssertTrue([alert.title isEqualToString:@"Disconnected Login"]);
////            [coordinator workOffline: parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////                NSLog(@"Auth Success");
////                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
////                XCTAssertTrue([[Authentication authenticationTypeToString:LOCAL] isEqualToString:[defaults valueForKey:@"loginType"]]);
////                XCTAssertTrue(authenticationStatus == AUTHENTICATION_SUCCESS);
////                [loginResponseArrived fulfill];
////            }];
////        });
//
//        OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            [disclaimerDelegate disclaimerAgree];
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            NSLog(@"Unable to authenticate");
////            XCTFail(@"Should not be in here");
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//            OCMVerifyAll(navControllerPartialMock);
//            OCMVerifyAll(coordinatorMock);
//            [storedPasswordMock stopMocking];
//        }];
//    }];
//}
//
//- (void) skipped_testWorkOfflineBadPassword {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setBool:YES forKey:@"deviceRegistered"];
//    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", @"test", @"username", nil] forKey:@"loginParameters"];
//
//    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
//    [[[storedPasswordMock stub] andReturn:@"goodpassword"] retrieveStoredPassword];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    __block AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"badpassword", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
//            return [HTTPStubsResponse responseWithError:notConnectedError];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//        id coordinatorMock = OCMPartialMock(coordinator);
//        OCMExpect([coordinatorMock unableToAuthenticate:[OCMArg any] complete:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//        }).andForwardToRealObject();
//
//        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            __unsafe_unretained UIAlertController *alert;
//            [invocation getArgument:&alert atIndex:2];
//            XCTAssertTrue([alert.title isEqualToString:@"Disconnected Login"]);
//            [coordinator workOffline: parameters complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
//                NSLog(@"Auth error");
//                XCTAssertTrue(authenticationStatus == AUTHENTICATION_ERROR);
//            }];
//        });
//
//        OCMStub([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[DisclaimerViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//            XCTFail(@"Should not have pushed the disclaimer");
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            NSLog(@"Unable to authenticate");
////            XCTFail(@"Should not be in here");
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//            OCMVerifyAll(navControllerPartialMock);
//            OCMVerifyAll(coordinatorMock);
//            [storedPasswordMock stopMocking];
//        }];
//
//    }];
//
//}
//
//- (void) skipped_testUnableToWorkOfflineDueToNoSavedPassword {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//    [defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:@"https://mage.geointservices.io", @"serverUrl", @"test", @"username", nil] forKey:@"loginParameters"];
//
//    id storedPasswordMock = [OCMockObject mockForClass:[StoredPassword class]];
//    [[[storedPasswordMock stub] andReturn:nil] retrieveStoredPassword];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    XCTestExpectation* apiResponseArrived = [self expectationWithDescription:@"response of /api complete"];
//
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    __block AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [apiResponseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/api"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        // response came back from the server and we went to the login screen
//        id<LoginDelegate> loginDelegate = (id<LoginDelegate>)coordinator;
//
//        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    @"test", @"username",
//                                    @"goodpassword", @"password",
//                                    @"uuid", @"uid",
//                                    [NSDictionary dictionaryWithObjectsAndKeys:
//                                     @"local", @"identifier", nil],
//                                    @"strategy",
//                                    nil];
//
//        [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//            return [request.URL.host isEqualToString:@"mage.geointservices.io"] && [request.URL.path isEqualToString:@"/auth/local/signin"];
//        } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
//            return [HTTPStubsResponse responseWithError:notConnectedError];
//        }];
//
//        XCTestExpectation* loginResponseArrived = [self expectationWithDescription:@"response of /auth/local/signin complete"];
//        id coordinatorMock = OCMPartialMock(coordinator);
//        OCMExpect([coordinatorMock unableToAuthenticate:[OCMArg any] complete:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
//            [loginResponseArrived fulfill];
//        }).andForwardToRealObject();
//
//        OCMExpect([navControllerPartialMock presentViewController:[OCMArg isKindOfClass:[UIAlertController class]] animated:YES completion:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            __unsafe_unretained UIAlertController *alert;
//            [invocation getArgument:&alert atIndex:2];
//            XCTAssertTrue([alert.title isEqualToString:@"Unable to Login"]);
//            [coordinator returnToLogin: ^(AuthenticationStatus authenticationStatus, NSString *errorString) {
//                NSLog(@"Auth error");
//                XCTAssertTrue([@"We are unable to connect to the server. Please try logging in again when your connection to the internet has been restored." isEqualToString:errorString]);
//                XCTAssertTrue(authenticationStatus == UNABLE_TO_AUTHENTICATE);
//            }];
//        });
//
////        [loginDelegate loginWithParameters:parameters withAuthenticationType:SERVER complete:^(AuthenticationStatus authenticationStatus, NSString *errorString) {
////            NSLog(@"Unable to authenticate");
////            XCTFail(@"Should not be in here");
////        }];
//
//        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//            OCMVerifyAll(navControllerPartialMock);
//            OCMVerifyAll(coordinatorMock);
//            [storedPasswordMock stopMocking];
//        }];
//    }];
//}
//
//- (void)skipped_testSetURLSuccess {
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[LoginViewController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        [responseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiSuccess.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
//    id<ServerURLDelegate> serverUrlDelegate = (id<ServerURLDelegate>)coordinator;
//    [serverUrlDelegate setServerURL:[NSURL URLWithString:@"https://mage.geointservices.io"]];
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        OCMVerifyAll(navControllerPartialMock);
//    }];
//}
//
//- (void)skipped_testSetURLCancel {
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[ServerURLController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        NSLog(@"server url controller pushed");
//    });
//    OCMExpect([navControllerPartialMock popViewControllerAnimated:NO])._andDo(^(NSInvocation *invocation) {
//        [responseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        XCTFail(@"No network requests should be made when the cancel action is taken after setting the server url");
//        return nil;
//    }];
//
//    id<ServerURLDelegate> serverUrlDelegate = (id<ServerURLDelegate>)coordinator;
//    [coordinator changeServerURL];
//    [serverUrlDelegate cancelSetServerURL];
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        OCMVerifyAll(navControllerPartialMock);
//    }];
//}
//
//- (void)skipped_testSetURLFailVersion {
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    __block id serverUrlControllerMock;
//    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[ServerURLController class]] animated:NO]);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@""]);
//
////    [coordinator start];
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        serverUrlControllerMock = OCMPartialMock(coordinator.urlController);
//        OCMExpect([serverUrlControllerMock showError:[OCMArg any]])._andDo(^(NSInvocation *invocation) {
//            [responseArrived fulfill];
//        });
//        NSString* fixture = OHPathForFile(@"apiFail.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
//    id<ServerURLDelegate> serverUrlDelegate = (id<ServerURLDelegate>)coordinator;
//    [serverUrlDelegate setServerURL:[NSURL URLWithString:@"https://mage.geointservices.io"]];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        OCMVerifyAll(navControllerPartialMock);
//        OCMVerifyAll(serverUrlControllerMock);
//    }];
//}
//
//- (void) skipped_testStartWithVersionFail {
//    NSString *baseUrlKey = @"baseServerUrl";
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"https://mage.geointservices.io" forKey:baseUrlKey];
//
//    UINavigationController *navigationController = [[UINavigationController alloc]init];
//
//    __block id serverUrlControllerMock;
//    XCTestExpectation* responseArrived = [self expectationWithDescription:@"response of async request has arrived"];
//    AuthenticationTestDelegate *delegate = [[AuthenticationTestDelegate alloc] init];
//
//    AuthenticationCoordinator *coordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:navigationController andDelegate:delegate andScheme:[MAGEScheme scheme]];
//
//    id navControllerPartialMock = OCMPartialMock(navigationController);
//
//    NSURL *url = [MageServer baseURL];
//    XCTAssertTrue([[url absoluteString] isEqualToString:@"https://mage.geointservices.io"]);
//
//    OCMExpect([navControllerPartialMock pushViewController:[OCMArg isKindOfClass:[ServerURLController class]] animated:NO])._andDo(^(NSInvocation *invocation) {
//        serverUrlControllerMock = OCMPartialMock(coordinator.urlController);
//        NSString *error = (NSString *)[serverUrlControllerMock error];
//
//        XCTAssertTrue([@"This version of the app is not compatible with version 4.0.0 of the server." isEqualToString:error]);
//        [responseArrived fulfill];
//    });
//
//    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
//        return [request.URL.host isEqualToString:@"mage.geointservices.io"];
//    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
//        NSString* fixture = OHPathForFile(@"apiFail.json", self.class);
//        return [HTTPStubsResponse responseWithFileAtPath:fixture
//                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
//    }];
//
////    [coordinator start];
//
//    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
//        OCMVerifyAll(navControllerPartialMock);
//    }];
//}
//
//@end
