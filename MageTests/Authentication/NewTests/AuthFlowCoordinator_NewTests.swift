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
    
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Fresh window + nav
        window = UIWindow(frame: UIScreen.main.bounds)
        nav = UINavigationController()
        nav.isNavigationBarHidden = true
        window.rootViewController = nav
        window.makeKeyAndVisible()
        
        // Clear legacy auth state
        MageSessionManager.shared()?.clearToken()
        StoredPassword.clearToken()
        clearAllUserDefaults()
        
        // Bootstrap the new auth dependencies (should mirror MageDependencyBootstrap.configure())
        AuthDependencies.shared.sessionStore = MageSessionStore.shared
        let base = URL(string: "https://magetest")!
        UserDefaults.standard.baseServerUrl = base.absoluteString
        AuthDependencies.shared.configureAuthServiceIfNeeded(baseURL: base, session: .shared)
        
        // Coordinator under test
        delegate = MockAuthDelegate()
        let scheme = MAGEScheme.scheme()
        coordinator = AuthFlowCoordinator(
            navigationController: nav,
            andDelegate: delegate,
            andScheme: scheme,
            context: nil)
        
        // ---- Stubs (re-use legacy helper + fixtures) ----
        HTTPStubs.removeAllStubs()
        serverStubDelegate = MockMageServerDelegate()
        
        // Some builds hit /api, others /api/server — stub both to be safe,
        // using the same fixture the legacy tests use.
        MockMageServer.stubJSONSuccessRequest(
            url: "https://magetest/api",
            filePath: "apiSuccess6.json",
            delegate: serverStubDelegate
        )

        MockMageServer.stubJSONSuccessRequest(
            url: "https://magetest/api/server",
            filePath: "apiSuccess6.json",
            delegate: serverStubDelegate
        )
    }
    
    override func tearDown() async throws {
        HTTPStubs.removeAllStubs()
        
        coordinator = nil
        delegate = nil
        serverStubDelegate = nil
        
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
    
    /// Mirrors “testStartLoginOnly” from the old suite: with a base URL present,
    /// startLoginOnly() should fetch server.json and push LoginHostViewController.
    func test_startLoginOnly_fetchesServerAndShowsLogin() async {
        // Ensure base URL is set the same way production boot does
        UserDefaults.standard.baseServerUrl = "https://magetest"
        
        // When
        coordinator.startLoginOnly()

        // 1) Wait until our legacy stub recorded either /api or /api/server
        let apiHit = expectation(for: NSPredicate { _,_ in
            let urls = self.serverStubDelegate.urls
            return  urls.contains(URL(string: "https://,agetest/api")!) ||
                    urls.contains(URL(string: "https://,agetest/api/server")!)
        }, evaluatedWith: nil)
        
        // 2) Wait until the coordinator captured the MageServer
        let serverSet = expectation(for: NSPredicate { _,_ in
            self.coordinator.server != nil
        }, evaluatedWith: nil)
        
        // 3) Wait until the login host is pushed
        let showsLoginHost = expectation(for: NSPredicate { _,_ in
            self.nav.topViewController is LoginHostViewController
        }, evaluatedWith: nil)
        
        await fulfillment(of: [apiHit, serverSet, showsLoginHost], timeout: 4.0)

    }
}
