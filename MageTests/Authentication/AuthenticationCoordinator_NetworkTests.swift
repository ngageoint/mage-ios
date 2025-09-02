//
//  AuthenticationCoordinator_NetworkTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/27/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class AuthenticationCoordinator_NetworkTests: AsyncMageCoreDataTestCase {
    
    @MainActor
    func test_LocalLogin_triggersSigninAndToken() async throws {
        let nav = UINavigationController()
        let delegate = MockAuthenticationCoordinatorDelegate()
        let coordinator = AuthenticationCoordinatorSpy(navigationController: nav,
                                                       andDelegate: delegate,
                                                       andScheme: MAGEScheme.scheme(),
                                                       context: context)!
        
        UserDefaults.standard.baseServerUrl = "https://magetest"
        
        // Stub API and endpoints
        let serverDelegate = MockMageServerDelegate()
        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api/server", filePath: "server_response.json", delegate: serverDelegate)
        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api", filePath: "apiSuccess6.json", delegate: serverDelegate)
        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/local/signin", filePath: "signinSuccess.json", delegate: serverDelegate)
        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/auth/token", filePath: "tokenSuccess.json", delegate: serverDelegate)
        
        let server: MageServer = await TestHelpers.getTestServer()
        coordinator.start(server)
        
        let params: [AnyHashable: Any] = [
            "username": "username",
            "password": "password",
            "uid": "uuid",
            "appVersion": "6.0.0",
            "strategy": ["identifier": "local"]
        ]
        
        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { _, _ in }
        
        let signinURL = URL(string: "https://magetest/auth/local/signin")!
        let tokenURL = URL(string: "https://magetest/auth/token")!
        
        let expSignin = expectation(description: "signin")
        let expToken = expectation(description: "token")
        
        Task { [weak serverDelegate] in
            while !(serverDelegate?.urls.contains(signinURL) ?? false) {
                try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
            }
            expSignin.fulfill()
        }

        Task { [weak serverDelegate] in
            while !(serverDelegate?.urls.contains(tokenURL) ?? false) {
                try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
            }
            expToken.fulfill()
        }
        
        await fulfillment(of: [expSignin, expToken], timeout: 3.0)
    }
}
