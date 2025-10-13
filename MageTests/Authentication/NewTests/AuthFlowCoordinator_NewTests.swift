//
//  AuthFlowCoordinator_NewTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import MAGE
@testable import Authentication

// Minimal delegate we can assert on
private final class MockAuthDelegate: NSObject, AuthenticationDelegate {
    var authenticationSuccessfulCalled = false
    var couldNotAuthenticateCalled = false
    var changeServerUrlCalled = false
    
    func authenticationSuccessful() { authenticationSuccessfulCalled = true }
    func couldNotAuthenticate() { couldNotAuthenticateCalled = true }
    func changeServerURL() { changeServerUrlCalled = true }
}

@MainActor
final class AuthFlowCoordinator_NewTests: XCTestCase {
    private var window: UIWindow!
    private var nav: UINavigationController!
    private var delegate: MockAuthDelegate!
    private var coordinator: AuthFlowCoordinator!
    
    private var serverStubDelegate: MockMageServerDelegate!
    
    private var calledURLs: [URL] = []
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Fresh window + nav
        window = UIWindow(frame: UIScreen.main.bounds)
        nav = UINavigationController()
        nav.isNavigationBarHidden = true
        window.rootViewController = nav
        window.makeKeyAndVisible()
        
        // Clean legacy auth state
        MageSessionManager.shared()?.clearToken()
        StoredPassword.clearToken()
        clearAllUserDefaults()
        
        // Bootstrap the new auth deps (mirrors MageDependencyBootstrap.configure())
        AuthDependencies.shared.sessionStore = MageSessionStore.shared
        let base = URL(string: "https://magetest")!
        UserDefaults.standard.baseServerUrl = base.absoluteString
        AuthDependencies.shared.configureAuthServiceIfNeeded(baseURL: base, session: .shared)
        
        // System under test
        delegate = MockAuthDelegate()
        coordinator = AuthFlowCoordinator(
            navigationController: nav,
            andDelegate: delegate,
            andScheme: MAGEScheme.scheme(),
            context: nil
        )
        
        // ---- Stubs ----
        HTTPStubs.removeAllStubs()
        HTTPStubs.setEnabled(true, for: URLSessionConfiguration.default)
        HTTPStubs.setEnabled(true, for: URLSessionConfiguration.ephemeral)
        
        // Record any stub activation
        calledURLs.removeAll()
        HTTPStubs.onStubActivation { [weak self] request, _, _ in
            if let u = request.url { self?.calledURLs.append(u) }
        }
        
        // Safety-net stub: any request to https://magetest that starts with /api
        // This covers both /api and /api/server which older code alternates between.
        let apiBody = """
        {
          "version": 6,
          "authenticationStrategies":[{"identifier":"local","type":"local","title":"Username/Password"}],
          "disclaimer": null
        }
        """
        HTTPStubs.stubRequests(passingTest: { req in
            guard let u = req.url else { return false }
            return u.host == "magetest" && u.path.hasPrefix("/api")
        }, withStubResponse: { _ in
            HTTPStubsResponse(
                data: Data(apiBody.utf8),
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }).name = "fallback-/api"
    }
    
    
    override func tearDown() async throws {
        HTTPStubs.removeAllStubs()
        
        coordinator = nil
        delegate = nil
        
        window.isHidden = true
        window.rootViewController = nil
        nav = nil
        window = nil
        
        MageSessionManager.shared()?.clearToken()
        StoredPassword.clearToken()
        clearAllUserDefaults()
        
        try await super.tearDown()
    }
    
    private func clearAllUserDefaults() {
        let defaults = UserDefaults.standard
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        defaults.synchronize()
    }
    
    // MARK: - Tests
    
    /// Replaces old "testShowLoginViewForServerCalled" with a direct UI assertion:
    /// after calling start(_:) the stack should show LoginHostViewController.
    func test_start_withKnownServer_pushesLoginHost() async {
        // Given a MageServer we already know
        let base = URL(string: "https://magetest")!
        let server = MageServer(url: base)
        
        // When
        coordinator.start(server)
        
        // Then
        let exp = expectation(description: "Login host presented")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertTrue(self.nav.topViewController is LoginHostViewController,
                          "Expected LoginHostViewController on top of the nav stack")
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    /// Mirrors old “testStartLoginOnly”:
    /// with a base URL present, startLoginOnly() should fetch server.json and push LoginHostViewController.
    func test_startLoginOnly_fetchesServerAndShowsLogin() async {
        // Ensure base URL is set as production does
        UserDefaults.standard.baseServerUrl = "https://magetest"
        
        // When
        coordinator.startLoginOnly()
        
        // 1) Wait until any /api* request to magetest actually fired
        let apiHit = expectation(for: NSPredicate { _, _ in
            self.calledURLs.contains { $0.host == "magetest" && $0.path.hasPrefix("/api") }
        }, evaluatedWith: nil)
        
        // 2) Wait until the coordinator captured the MageServer
        let serverSet = expectation(for: NSPredicate { _, _ in
            self.coordinator.server != nil
        }, evaluatedWith: nil)
        
        // 3) Wait until the login host is pushed
        let showsLoginHost = expectation(for: NSPredicate { _, _ in
            self.nav.topViewController is LoginHostViewController
        }, evaluatedWith: nil)
        
        await fulfillment(of: [apiHit, serverSet, showsLoginHost], timeout: 4.0)
    }
}
