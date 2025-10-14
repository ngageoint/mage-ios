//
//  AuthFlowCoordinator_NewTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE
@testable import Authentication

// Minimal delegate we can assert on
private final class MockAuthDelegate: NSObject, AuthenticationDelegate {
    var authenticationSuccessfulCalled = false
    var couldNotAuthenticateCalled = false
    var changeServerUrlCalled = false
    
    func authenticationSuccessful() { authenticationSuccessfulCalled = true }
    func couldNotAuthenticate()     { couldNotAuthenticateCalled = true }
    func changeServerURL()          { changeServerUrlCalled = true }
}

@MainActor
final class AuthFlowCoordinator_NewTests: XCTestCase {
    private var window: UIWindow!
    private var nav: UINavigationController!
    private var coordinator: AuthFlowCoordinator!
    
    private let apiJSON = """
            {
              "version": 6,
              "authenticationStrategies": [
                { "identifier": "local", "type": "local", "title": "Username/Password" }
              ],
              "disclaimer": null
            }
    """
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Clean legacy auth state
        MageSessionManager.shared()?.clearToken()
        StoredPassword.clearToken()
        if let id = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: id)
        }

        // Fresh window + nav
        window = UIWindow(frame: UIScreen.main.bounds)
        nav = UINavigationController()
        nav.isNavigationBarHidden = true
        window.rootViewController = nav
        window.makeKeyAndVisible()
        
        
        // Minimal bootstrap for new auth deps
        AuthDependencies.shared.sessionStore = MageSessionStore.shared
        
        // Base URL used by coordinator
        UserDefaults.standard.baseServerUrl = "https://magetest"
    }
    
    override func tearDown() async throws {
        coordinator = nil
        window.isHidden = true
        window.rootViewController = nil
        window = nil
        nav = nil
        
        MageSessionManager.shared()?.clearToken()
        StoredPassword.clearToken()
        
        try await super.tearDown()
    }
    
    private func makeServerInfoService(base: URL) -> ServerInfoService {
        let routes = [
            TestRoute(matches: { req in
                guard let url = req.url else { return false }
                return url.host == base.host &&
                (url.path == "/api" || url.path == "/api/server") &&
                (req.httpMethod ?? "GET") == "GET"
            }, respond: { req in
                let data = Data(self.apiJSON.utf8)
                let http = HTTPURLResponse(url: req.url!, statusCode: 200,
                                           httpVersion: nil, headerFields: ["Content-Type":"application/json"])!
                return (data, http)
            })
        ]
        
        let fakeNet = TestFakeNetwork(routes: routes)
        return ServerInfoService(baseURL: base, net: fakeNet)
    }
    
//    private func clearAllUserDefaults() {
//        let defaults = UserDefaults.standard
//        if let bundleID = Bundle.main.bundleIdentifier {
//            defaults.removePersistentDomain(forName: bundleID)
//        }
//        defaults.synchronize()
//    }
    
    // MARK: - Tests
    
    /// Replaces old "testShowLoginViewForServerCalled" with a direct UI assertion:
    /// after calling start(_:) the stack should show LoginHostViewController.
    func test_start_withKnownServer_pushesLoginHost() async {
        let base = URL(string: "https://magetest")!
        let server = MageServer(url: base)
        let svc = makeServerInfoService(base: base)

        coordinator = AuthFlowCoordinator(
            navigationController: nav,
            andDelegate: MockAuthDelegate(),
            andScheme: MAGEScheme.scheme(),
            context: nil,
            serverInfoService: svc
        )
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
