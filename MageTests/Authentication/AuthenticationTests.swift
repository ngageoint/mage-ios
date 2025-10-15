//
//  AuthenticationTests.m
//  MAGETests
//
//  Created by Dan Barela on 1/9/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Authentication


@testable import MAGE

class AuthenticationTestDelegate: NSObject, AuthenticationDelegate {
    var authenticationSuccessfulCalled = false
    var couldNotAuthenticateCalled = false
    var changeServerURLCalled = false
    
    func authenticationSuccessful() { authenticationSuccessfulCalled = true }
    func couldNotAuthenticate()     { couldNotAuthenticateCalled = true }
    func changeServerURL()          { changeServerURLCalled = true }
}

@MainActor
final class AuthenticationTests: AsyncMageCoreDataTestCase {
    
    var window: UIWindow!
    
    override func setUp() async throws {
        try await super.setUp()
        window = TestHelpers.getKeyWindowVisible();
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        window.rootViewController = nil;
    }
    
    func testLoginWithRegisteredDevice() async {
        TestHelpers.setupTestSession()
        
        let navigationController = TestHelpers.initializeTestNavigation()
        let delegate = MockAuthenticationCoordinatorDelegate()
        let server: MageServer = await TestHelpers.getTestServer()
        
        let coordinator = AuthFlowCoordinator(
            navigationController: navigationController,
            andDelegate: delegate,
            andScheme: MAGEScheme.scheme(),
            context: context
        )
        
        coordinator.start(server)
        
        await TestHelpers.waitForLoginScreen(navigationController: navigationController)
        TestHelpers.executeTestLogin(coordinator: coordinator)
        await TestHelpers.handleDisclaimerAcceptance(coordinator: coordinator, navigationController: navigationController)
        await TestHelpers.waitForAuthenticationSuccess(delegate: delegate)
        
        XCTAssertTrue(delegate.authenticationSuccessfulCalled, "Expected authenticationSuccessful to be called")
    }
    
    func testRegisterDevice() async {
        TestHelpers.setupTestSession()
        MockMageServer.stubRegisterDeviceResponses()
        
        let navigationController = TestHelpers.initializeTestNavigation()
        let delegate = MockAuthenticationCoordinatorDelegate()
        let server: MageServer = await TestHelpers.getTestServer()
        
        let coordinator = AuthFlowCoordinator(
            navigationController: navigationController,
            andDelegate: delegate,
            andScheme: MAGEScheme.scheme(),
            context: context
        )
        
        coordinator.start(server)
        
        await TestHelpers.waitForLoginScreen(navigationController: navigationController)
        
        let deviceRegistered = XCTestExpectation(description: "device registered")
        TestHelpers.executeTestLoginForRegistration(coordinator: coordinator, expectation: deviceRegistered)
        
        await fulfillment(of: [deviceRegistered], timeout: 2)
        
        tester().waitForView(withAccessibilityLabel: "Registration Sent")
    }
    
    func testLoginWithUpdatedUser() async {
        // Step 1: Setup test session & pre-create user
        TestHelpers.setupTestSession()
        MageCoreDataFixtures.addUser(userId: "1a")
        
        let navigationController = TestHelpers.initializeTestNavigation()
        let delegate = MockAuthenticationCoordinatorDelegate()
        let server: MageServer = await TestHelpers.getTestServer()
        
        // Step 2: Verify user info BEFORE login
        guard let context else {
            XCTFail("Missing Core Data Context")
            return
        }
        context.performAndWait {
            let user = context.fetchFirst(User.self,
                                          key: UserKey.remoteId.key,
                                          value: "1a")!
            XCTAssertEqual(user.name, "User ABC", "User name should be 'User ABC' before login")
        }
        
        // Step 3: Start authentication
        let coordinator = AuthFlowCoordinator(
            navigationController: navigationController,
            andDelegate: delegate,
            andScheme: MAGEScheme.scheme(),
            context: context
        )
        
        coordinator.start(server)
        
        await TestHelpers.waitForLoginScreen(navigationController: navigationController)
        
        // Step 4: Execute login
        let loginExpectation = XCTestExpectation(description: "User attempts to log in")
        TestHelpers.executeTestLogin(coordinator: coordinator, expectation: loginExpectation)
        
        // Step 5: Proceed through disclaimer if applicable
        await TestHelpers.waitForDisclaimerScreen(navigationController: navigationController)
        await TestHelpers.handleDisclaimerAcceptance(coordinator: coordinator, navigationController: navigationController)
        
        await TestHelpers.waitForAuthenticationSuccess(delegate: delegate)
        XCTAssertTrue(delegate.authenticationSuccessfulCalled, "Authentication was not successful")
        
        // Step 6: Verify user info AFTER login
        context.performAndWait {
            let user = context.fetchFirst(User.self,
                                          key: UserKey.remoteId.key,
                                          value: "1a")!
            XCTAssertEqual(user.name, "Firstname Lastname", "User name was not updated after login")
        }
    }
}
