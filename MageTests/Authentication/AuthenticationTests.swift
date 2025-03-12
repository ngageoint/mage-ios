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
//protocol AuthenticationServiceProtocol {
//    func signIn(username: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void)
//    func fetchAuthToken(uid: String, completion: @escaping (Result<TokenResponse, Error>) -> Void)
//}
//
//struct AuthResponse: Codable {
//    let token: String
//    let userId: String
//}
//
//struct TokenResponse: Codable {
//    let accessToken: String
//}


// MARK: - Mock Authentication Service
//class MockAuthenticationService: AuthenticationServiceProtocol {
//    var shouldSucceed = true
//    var mockToken = "TOKEN"
//    
//    func signIn(username: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
//        if shouldSucceed {
//            completion(.success(AuthResponse(token: mockToken, userId: "1a")))
//        } else {
//            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: nil)))
//        }
//    }
//    
//    func fetchAuthToken(uid: String, completion: @escaping (Result<TokenResponse, Error>) -> Void) {
//        if shouldSucceed {
//            completion(.success(TokenResponse(accessToken: mockToken)))
//        } else {
//            completion(.failure(NSError(domain: "AuthError", code: 403, userInfo: nil)))
//        }
//    }
//}


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
    
    override func setUp() {
        super.setUp()
        
        window = UIWindow()
        navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        delegate = AuthenticationTestDelegate()
        
        coordinator = AuthenticationCoordinator(
            navigationController: navigationController,
            andDelegate: delegate,
            andScheme: MAGEScheme.scheme(),
            context: nil
        )
        
        stubAPIResponses()
    }
    
    override func tearDown() {
        HTTPStubs.removeAllStubs()  // ✅ Clean up network stubs
        coordinator = nil
        delegate = nil
        navigationController = nil
        window = nil
        super.tearDown()
    }

    /// ✅ Centralized API response stubbing
    private func stubAPIResponses() {
        stub(condition: isMethodPOST() && isPath("/auth/local/signin")) { _ in
            let responseJSON = ["token": "TOKEN", "userId": "1a"]
            return HTTPStubsResponse(jsonObject: responseJSON, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        stub(condition: isMethodPOST() && isPath("/auth/token")) { _ in
            let responseJSON = ["accessToken": "TOKEN"]
            return HTTPStubsResponse(jsonObject: responseJSON, statusCode: 200, headers: ["Content-Type": "application/json"])
        }
        
        // ✅ Debugging stub to log unmatched requests
        stub(condition: { request in
            print("🔍 HTTP Request: \(request.url?.absoluteString ?? "Unknown")")
            return false
        }) { _ in
            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: URLError.cannotConnectToHost.rawValue))
        }
    }
    
    // MARK: - 🛟 Helpers
    // ✅ Utility function to generate test login parameters
    private func generateLoginParameters(username: String, password: String) -> [String: Any] {
        return [
            "username": username,
            "password": password,
            "uid": "uuid",
            "strategy": ["identifier": "local"],
            "appVersion": "6.0.0"
        ]
    }
    
    // MARK: - 🧪 Test Cases

    @MainActor
    func testSuccessfulLogin() async {
        let loginExpectation = expectation(description: "Login should succeed")
        let loginDelegate = coordinator as! LoginDelegate

        let parameters = generateLoginParameters(username: "testUser", password: "password123")

        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, _ in
            XCTAssertEqual(authenticationStatus, AuthenticationStatus.AUTHENTICATION_SUCCESS)
            XCTAssertEqual(StoredPassword.retrieveStoredToken(), "TOKEN")
            loginExpectation.fulfill()
        }

        await fulfillment(of: [loginExpectation], timeout: 2.0)
    }

//    /// ✅ Helper function to stub API responses
//    func stubAPIResponses() {
//        // Stub /auth/local/signin
//        stub(condition: isMethodPOST() && isPath("/auth/local/signin")) { _ in
//            print("✅ Stub hit: /auth/local/signin") // Debugging log
//            let responseJSON = ["token": "TOKEN", "userId": "1a"]
//            return HTTPStubsResponse(jsonObject: responseJSON, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        // Stub /auth/token
//        stub(condition: isMethodPOST() && isPath("/auth/token")) { _ in
//            print("✅ Stub hit: /auth/token") // Debugging log
//            let responseJSON = ["accessToken": "TOKEN"]
//            return HTTPStubsResponse(jsonObject: responseJSON, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        stub(condition: { request in
//            print("🔍 HTTP Request: \(request.url?.absoluteString ?? "Unknown")")
//            return false
//        }) { _ in
//            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: URLError.cannotConnectToHost.rawValue))
//        }
//    }
//    
    // MARK: - Test Cases

//    func testSuccessfulLogin() {
//        let expectation = XCTestExpectation(description: "Login should succeed")
//        let loginDelegate = coordinator as! LoginDelegate
//        
//        let parameters: [String: Any] = [
//            "username": "testUser",
//            "password": "password123",
//            "uid": "uuid",
//            "strategy": ["identifier": "local"],
//            "appVersion": "6.0.0"
//        ]
//        
//        print("🚀 Initiating login request...")
//        
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, _ in
//            print("✅ Login completion block called")  // Debugging log
//            XCTAssertEqual(authenticationStatus, AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            
//            let storedToken = StoredPassword.retrieveStoredToken()
//            print("🔍 Stored Token:", storedToken ?? "nil")  // Debugging log
//            
//            XCTAssertEqual(storedToken, "TOKEN")
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 2.0)
//    }

//    func testFailedLogin() {
//        mockAuthService.shouldSucceed = false
//        
//        let expectation = XCTestExpectation(description: "Login should fail")
//        let loginDelegate = coordinator as! LoginDelegate
//        
//        let parameters: [String: Any] = [
//            "username": "invalidUser",
//            "password": "wrongPassword",
//            "uid": "uuid",
//            "strategy": ["identifier": "local"],
//            "appVersion": "6.0.0"
//        ]
//        
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, _ in
//            XCTAssertEqual(authenticationStatus, AuthenticationStatus.AUTHENTICATION_ERROR)
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 2.0)
//    }

//
//    @MainActor
//    private func verifyNavigationStackContains(_ expectedViewController: AnyClass, timeout: TimeInterval = 2) async {
//        await awaitBlockTrue(block: { [weak self] in
//            guard let self = self else { return false }
//            guard let navigationController = self.navigationController else {
//                XCTFail("❌ navigationController is nil before checking the navigation stack!")
//                return false
//            }
//
//            print("📌 Navigation Stack Contains: \(navigationController.viewControllers)")
//
//            let stack = navigationController.viewControllers.map { String(describing: type(of: $0)) }
//            print("📌 Navigation Stack: \(stack)")
//
//            let containsExpectedVC = navigationController.viewControllers.contains { $0.isKind(of: expectedViewController) }
//
//            if !containsExpectedVC {
//                XCTFail("❌ Expected \(expectedViewController), but got stack: \(stack)")
//                return false
//            }
//
//            return true
//        }, timeout: timeout)
//    }

    
//    @MainActor
//    func testLoginWithRegisteredDeviceAndRandomTokenBrent() async {
//        configureAuthenticationEnvironment()
//        configureUserDefaults()
//
//        // Create expectations dynamically
//        (apiExpectations, stubFulfillmentHandlers) = createAPIExpectations()
//        
//        // Apply the stubs
//        stubAPIResponses(with: stubFulfillmentHandlers)
//
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { server in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail("❌ Failed to create MageServer")
//            }
//        }
//        
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        coordinator = AuthenticationCoordinator(
//            navigationController: navigationController,
//            andDelegate: delegate,
//            andScheme: MAGEScheme.scheme(),
//            context: context
//        )!
//
//        // Ensure coordinator starts before checking the navigation stack
//        Task {
//            coordinator.start(server)
//            try? await Task.sleep(nanoseconds: 500_000_000)  // ⏳ Wait for 0.5 sec
//            await verifyNavigationStackContains(LoginViewController.self)
//        }
//            
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
//        let loginDelegate = coordinator as! LoginDelegate
//        print("🚀 Initiating login request...")
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            print("✅ Login response received! Status: \(authenticationStatus)")
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await verifyNavigationStackContains(DisclaimerViewController.self, timeout: 4)
//        
//        let disclaimerDelegate = coordinator as! DisclaimerDelegate
//        disclaimerDelegate.disclaimerAgree()
//        
//        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
//        
//        // Wait for API expectations to be fulfilled
//        await fulfillment(of: apiExpectations.values.map { $0 }, timeout: 5)
//    }
//
//    
//
//    @MainActor
//    func testLoginWithRegisteredDeviceAndRandomTokenBrentZZZ() async {
//        configureAuthenticationEnvironment()
//        configureUserDefaults()
//
//        // Create expectations dynamically
//        let (apiExpectations, stubFulfillmentHandlers) = createAPIExpectations()
//        
//        // Apply the stubs
//        stubAPIResponses(with: stubFulfillmentHandlers)
//
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        
//        Task {
//            coordinator.start(server)
//            await verifyNavigationStackContains(LoginViewController.self)
//        }
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await verifyNavigationStackContains(DisclaimerViewController.self)
//        
//        let disclaimerDelegate = coordinator as! DisclaimerDelegate
//        disclaimerDelegate.disclaimerAgree()
//        
//        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
//        
//        // Wait for API expectations to be fulfilled
//        await fulfillment(of: apiExpectations.values.map { $0 }, timeout: 5)
//    }

    
    
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
    
    
//    @MainActor
//    func testLoginWithRegisteredDeviceAndRandomToken_original() async {
//        let baseUrlKey = "baseServerUrl"
//        MageSessionManager.shared()?.setToken("TOKEN")
//        StoredPassword.persistToken(toKeyChain: "TOKEN")
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("authorizeLocalSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/api/users/1a/icon")
//        ) { (request) -> HTTPStubsResponse in
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("icon27.png", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "image/png"])
//        }
//        
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/api/users/1a/avatar")
//        ) { (request) -> HTTPStubsResponse in
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("icon27.png", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "image/png"])
//        }
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? DisclaimerViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let disclaimerDelegate = coordinator as! DisclaimerDelegate
//        disclaimerDelegate.disclaimerAgree()
//        
//        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
//        
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//    }
//    
//    @MainActor
//    func testRegisterDevice() async {
//        let baseUrlKey = "baseServerUrl"
//        MageSessionManager.shared()?.setToken("TOKEN")
//        StoredPassword.persistToken(toKeyChain: "TOKEN")
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            let response = HTTPStubsResponse()
//            response.statusCode = 403
//            return response
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        let deviceRegistered = XCTestExpectation(description: "device registered")
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.REGISTRATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
//            deviceRegistered.fulfill()
//        }
//        
//        await fulfillment(of: [deviceRegistered], timeout: 2)
//        tester().waitForView(withAccessibilityLabel: "Registration Sent")
//    }
//    
//    @MainActor
//    func testLoginWithRegisteredDevice() async {
//        let baseUrlKey = "baseServerUrl"
//        MageSessionManager.shared()?.setToken("TOKEN")
//        StoredPassword.persistToken(toKeyChain: "TOKEN")
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("authorizeLocalSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
////        let deviceRegistered = XCTestExpectation(description: "device registered")
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
//            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
//            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? DisclaimerViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("disclaimer title").view != nil &&
//            self.viewTester().usingLabel("disclaimer text").view != nil
//        }, timeout: 2)
//        
//        let disclaimerDelegate = coordinator as! DisclaimerDelegate
//        disclaimerDelegate.disclaimerAgree()
//        
//        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
//        
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginWithUpdatedUser() async {
//        MageCoreDataFixtures.addUser(userId: "1a");
//        
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("authorizeLocalSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        context.performAndWait {
//            let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: "1a")!
//            XCTAssertEqual(user.name, "User ABC")
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
////        let deviceRegistered = XCTestExpectation(description: "device registered")
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? DisclaimerViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("disclaimer title").view != nil &&
//            self.viewTester().usingLabel("disclaimer text").view != nil
//        }, timeout: 2)
//        
//        let disclaimerDelegate = coordinator as! DisclaimerDelegate
//        disclaimerDelegate.disclaimerAgree()
//        
//        XCTAssertTrue(delegate.authenticationSuccessfulCalled)
//        
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//        
//        context.performAndWait {
//            let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: "1a")!
//            XCTAssertEqual(user.name, "Firstname Lastname")
//        }
//    }
//    
//    @MainActor
//    func testLoginWithInactiveUser() async {
////        StoredPassword.clearToken()
//        
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccessInactiveUser.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
////        let deviceRegistered = XCTestExpectation(description: "device registered")
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.ACCOUNT_CREATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("MAGE Account Created").view != nil
//        }, timeout: 2)
//                
//        await fulfillment(of: [apiSigninResponseArrived], timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginWithNoConnection() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
//            return HTTPStubsResponse(error:notConnectedError)
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
////        let deviceRegistered = XCTestExpectation(description: "device registered")
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.ACCOUNT_CREATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Unable to Login").view != nil
//        }, timeout: 2)
//                
//        await fulfillment(of: [apiSigninResponseArrived], timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginFailed() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            let response = HTTPStubsResponse()
//            response.statusCode = 304
//            return response
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
////        let deviceRegistered = XCTestExpectation(description: "device registered")
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_ERROR)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Login Failed").view != nil
//        }, timeout: 2)
//                
//        await fulfillment(of: [apiSigninResponseArrived], timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginWithNoConnectionForToken() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
//            return HTTPStubsResponse(error:notConnectedError)
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
////        let deviceRegistered = XCTestExpectation(description: "device registered")
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Unable to Login").view != nil
//        }, timeout: 2)
//       
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginServerIncompatible() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            return HTTPStubsResponse(
//                jsonObject: [
//                    "expirationDate":"2020-02-20T01:25:44.796Z",
//                    "api":[
//                        "name":"mage-server",
//                        "description":"Geospatial situation awareness application.",
//                        "version":[
//                            "major":5,
//                            "minor":0,
//                            "micro":0
//                        ],
//                        "authenticationStrategies":[
//                            "local":[
//                                "passwordMinLength":14
//                            ]
//                        ],
//                        "provision":[
//                            "strategy":"uid"
//                        ]
//                    ]
//                ],
//                statusCode: 200,
//                headers: ["Content-Type": "application/json"]
//            )
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
////        let deviceRegistered = XCTestExpectation(description: "device registered")
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_ERROR)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Login Failed").view != nil
//        }, timeout: 2)
//       
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginWithOtherErrorForToken() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            let badServerResponse = NSError(domain: NSURLErrorDomain, code: URLError.badServerResponse.rawValue)
//            return HTTPStubsResponse(error:badServerResponse)
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
////        let deviceRegistered = XCTestExpectation(description: "device registered")
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_ERROR)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Login Failed").view != nil
//        }, timeout: 2)
//       
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginFailWithRegisteredDevice() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(data: "Test".data(using: .utf8)!, statusCode: 401, headers: nil)
//        }
//        
//
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_ERROR)
//            let token = StoredPassword.retrieveStoredToken()
//            XCTAssertEqual(token, "TOKEN")
//        }
//        
//        await fulfillment(of: [apiSigninResponseArrived], timeout: 2)
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Login Failed").view != nil
//        }, timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginWithInvalidToken() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            return HTTPStubsResponse(
//                jsonObject: [
//                    "expirationDate":"2020-02-20T01:25:44.796Z",
//                    "api":[
//                        "name":"mage-server",
//                        "description":"Geospatial situation awareness application.",
//                        "version":[
//                            "major":6,
//                            "minor":0,
//                            "micro":0
//                        ],
//                        "authenticationStrategies":[
//                            "local":[
//                                "passwordMinLength":14
//                            ]
//                        ],
//                        "provision":[
//                            "strategy":"uid"
//                        ]
//                    ]
//                ],
//                statusCode: 200,
//                headers: ["Content-Type": "application/json"]
//            )
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            print("Authentication status \(authenticationStatus)")
//            // TODO: This really should return AUTHENTICATION_ERROR but right now it returns success
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//        TestHelpers.printAllAccessibilityLabelsInWindows()
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Login Failed").view != nil &&
//            self.viewTester().usingLabel("Copy Error Message Detail").view != nil
//        }, timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginWithInvalidTokenExpirationDate() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            return HTTPStubsResponse(
//                jsonObject: [
//                    "token":"TOKEN",
//                    "api":[
//                        "name":"mage-server",
//                        "description":"Geospatial situation awareness application.",
//                        "version":[
//                            "major":6,
//                            "minor":0,
//                            "micro":0
//                        ],
//                        "authenticationStrategies":[
//                            "local":[
//                                "passwordMinLength":14
//                            ]
//                        ],
//                        "provision":[
//                            "strategy":"uid"
//                        ]
//                    ]
//                ],
//                statusCode: 200,
//                headers: ["Content-Type": "application/json"]
//            )
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            print("Authentication status \(authenticationStatus)")
//            // TODO: This really should return AUTHENTICATION_ERROR but right now it returns success
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//        TestHelpers.printAllAccessibilityLabelsInWindows()
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Login Failed").view != nil &&
//            self.viewTester().usingLabel("Copy Error Message Detail").view != nil
//        }, timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginWithInvalidUsername() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            return HTTPStubsResponse(
//                jsonObject: [
//                    "token":"TOKEN",
//                    "expirationDate":"2020-02-20T01:25:44.796Z",
//                    "api":[
//                        "name":"mage-server",
//                        "description":"Geospatial situation awareness application.",
//                        "version":[
//                            "major":6,
//                            "minor":0,
//                            "micro":0
//                        ],
//                        "authenticationStrategies":[
//                            "local":[
//                                "passwordMinLength":14
//                            ]
//                        ],
//                        "provision":[
//                            "strategy":"uid"
//                        ]
//                    ]
//                ],
//                statusCode: 200,
//                headers: ["Content-Type": "application/json"]
//            )
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
////            "username": "test",
//            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            print("Authentication status \(authenticationStatus)")
//            // TODO: This really should return AUTHENTICATION_ERROR but right now it returns success
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//        TestHelpers.printAllAccessibilityLabelsInWindows()
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Login Failed").view != nil &&
//            self.viewTester().usingLabel("Copy Error Message Detail").view != nil
//        }, timeout: 2)
//    }
//    
//    @MainActor
//    func testLoginWithInvalidPassword() async {
//        let baseUrlKey = "baseServerUrl"
//        
//        let defaults = UserDefaults.standard
//        defaults.set("https://magetest", forKey: baseUrlKey)
//        defaults.set(true, forKey: "deviceRegistered")
//        
//        let navigationController = UINavigationController()
//        window.rootViewController = navigationController
//        
//        let delegate = AuthenticationTestDelegate()
//        
//        let url = MageServer.baseURL()
//        
//        let apiResponseArrived = XCTestExpectation(description: "response of /api complete")
//        
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isPath("/api")
//        ) { (request) -> HTTPStubsResponse in
//            apiResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("apiSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let server: MageServer = await withCheckedContinuation { continuation in
//            MageServer.server(url: url) { (server: MageServer) in
//                continuation.resume(returning: server)
//            } failure: { error in
//                XCTFail()
//            }
//        }
//        XCTAssertEqual(url?.absoluteString, "https://magetest")
//        
//        let apiSigninResponseArrived = XCTestExpectation(description: "response of /auth/local/signin complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/local/signin")
//        ) { (request) -> HTTPStubsResponse in
//            apiSigninResponseArrived.fulfill()
//            return HTTPStubsResponse(fileAtPath: OHPathForFile("signinSuccess.json", AuthenticationTests.self)!, statusCode: 200, headers: ["Content-Type": "application/json"])
//        }
//        
//        let apiTokenStub = XCTestExpectation(description: "response of /auth/token complete")
//
//        stub(condition: isMethodPOST() &&
//             isHost("magetest") &&
//             isPath("/auth/token")
//        ) { (request) -> HTTPStubsResponse in
//            apiTokenStub.fulfill()
//            return HTTPStubsResponse(
//                jsonObject: [
//                    "token":"TOKEN",
//                    "expirationDate":"2020-02-20T01:25:44.796Z",
//                    "api":[
//                        "name":"mage-server",
//                        "description":"Geospatial situation awareness application.",
//                        "version":[
//                            "major":6,
//                            "minor":0,
//                            "micro":0
//                        ],
//                        "authenticationStrategies":[
//                            "local":[
//                                "passwordMinLength":14
//                            ]
//                        ],
//                        "provision":[
//                            "strategy":"uid"
//                        ],
//                        "contactinfo": [
//                            "email": "test@test.com",
//                            "phone": "555-555-5555"
//                        ]
//                    ]
//                ],
//                statusCode: 200,
//                headers: ["Content-Type": "application/json"]
//            )
//        }
//        
//        let coordinator = AuthenticationCoordinator(navigationController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme(), context: context)!
//        coordinator.start(server)
//        
//        await awaitBlockTrue(block: {
//            if let _ = navigationController.topViewController as? LoginViewController {
//                return true
//            }
//            return false
//        }, timeout: 2)
//        
//        let parameters: [String: Any] = [
//            "username": "test",
////            "password": "test",
//            "uid": "uuid",
//            "strategy": [
//                "identifier": "local"
//            ],
//            "appVersion": "6.0.0"
//        ]
//        
//        let loginDelegate = coordinator as! LoginDelegate
//        loginDelegate.login(withParameters: parameters, withAuthenticationStrategy: "local") { authenticationStatus, errorString in
//            // login complete
//            print("Authentication status \(authenticationStatus)")
//            // TODO: This really should return AUTHENTICATION_ERROR but right now it returns success
//            XCTAssertTrue(authenticationStatus == AuthenticationStatus.AUTHENTICATION_SUCCESS)
//            let token = StoredPassword.retrieveStoredToken()
////            let mageSessionToken = MageSessionManager.shared().getToken()
//            XCTAssertEqual(token, "TOKEN")
////            XCTAssertEqual(token, mageSessionToken)
//        }
//        
//        await fulfillment(of: [apiSigninResponseArrived, apiTokenStub], timeout: 2)
//        TestHelpers.printAllAccessibilityLabelsInWindows()
//        
//        await awaitBlockTrue(block: {
//            self.viewTester().usingLabel("Login Failed").view != nil &&
//            self.viewTester().usingLabel("Copy Error Message Detail").view != nil
//        }, timeout: 2)
//        TestHelpers.printAllAccessibilityLabelsInWindows()
//    }
}
