//
//  AuthFlowCoordinator_ParityTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 9/25/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE
import Authentication

// MARK: - Shared helper + fake module

@MainActor
func makeServer(mods: [String: AuthenticationModule]) -> MageServer {
    let server = MageServer(url: URL(string: "https://magetest")!)
    // The property is accessed by the coordinator; use KVC to avoid visibility issues.
    server.setAuthenticationModulesForTests(mods)
    return server
}

final class FakeAuthModule: AuthenticationModule {
    enum Mode { case success, registration, accountCreation, error(String), unable }
    var mode: Mode = .success
    
    required init(parameters: [AnyHashable: Any]?) {}
    
    func canHandleLogin(toURL url: String) -> Bool { true }
    
    func login(withParameters params: [AnyHashable: Any],
               complete: @escaping (AuthenticationStatus, String?) -> Void) {
        switch mode {
        case .success: complete(.success, nil)
        case .registration: complete(.registrationSuccess, nil)
        case .accountCreation: complete(.accountCreationSuccess, nil)
        case .error(let message): complete(.error, message)
        case .unable: complete(.unableToAuthenticate, "unable")
        }
    }
    
    func finishLogin(_ complete: @escaping (AuthenticationStatus, String? , String?) -> Void) {
        complete(.success, nil, nil)
    }
}

// MARK: - Tests

@MainActor
final class AuthFlowCoordinator_ParityTests: XCTestCase {

    // Spy delegate to assert callbacks
    final class SpyAuthDelegate: NSObject, AuthenticationDelegate {
        var didAuthSuccess = false
        var didCouldNotAuthenticate = false
        
        var successExpectation: XCTestExpectation?
        
        var onSuccess: (() -> Void)?

        func authenticationSuccessful() {
            didAuthSuccess = true
            successExpectation?.fulfill()
        }
        
        func couldNotAuthenticate() { didCouldNotAuthenticate = true }
        func changeServerUrl() { }
    }

    var server: MageServer!
    var delegate: (any AuthenticationDelegate)!
    var coordinator: AuthFlowCoordinator!
    
    
    override func setUp() async throws {
        try await super.setUp()
        
        let nav = UINavigationController()
        delegate = SpyAuthDelegate()
        
        coordinator = AuthFlowCoordinator(
            navigationController: nav,
            andDelegate: delegate,
            andScheme: nil,
            context: nil
        )
  
        // Default server with both modules present
        let local   = FakeAuthModule(parameters: nil); local.mode = .success
        let offline = FakeAuthModule(parameters: nil); offline.mode = .success
        server = makeServer(mods: ["local": local, "offline": offline])
        coordinator.server = server

        // Reset flags used by some code paths (if your app checks these keys)
        UserDefaults.standard.removeObject(forKey: "loginType")
        UserDefaults.standard.removeObject(forKey: "showDisclaimer")
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        (delegate as? SpyAuthDelegate)?.successExpectation = nil
        UserDefaults.standard.removeObject(forKey: "loginType")
        UserDefaults.standard.removeObject(forKey: "showDisclaimer")
    }
    
    func test_ModuleSelection_RequestedThenFallbackThenUnable() {
        let params: NSDictionary = ["username": "u", "password": "p", "serverUrl": "https://magetest"]
        
        // Requested strategy present
        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { status, _ in
            XCTAssertEqual(status, .success)
        }
        
        // Remove "local" - falls back to "offline"
        let fallbackOnly = ["offline": FakeAuthModule(parameters: nil)]
        server.setAuthenticationModulesForTests(fallbackOnly)
        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { status, _ in
            XCTAssertEqual(status, .success)
        }
        
        // Remove everything - unable
        server.setAuthenticationModulesForTests([:])
        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { status, _ in
            XCTAssertEqual(status, .unableToAuthenticate)
        }
    }
    
    func test_Success_NoDisclaimer_SignalsAuthenticatedImmediately() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "showDisclaimer")
        defaults.set("local", forKey: "loginType")
        defaults.synchronize()
        
        let successExp = expectation(description: "delegate signalled success")
        (delegate as! SpyAuthDelegate).successExpectation = successExp

        let params: NSDictionary = ["username": "alice", "password": "pw", "serverUrl": "https://magetest"]
        coordinator.login(withParameters: params, withAuthenticationStrategy: "local") { status, _ in
            XCTAssertEqual(status, .success)
        }

        waitForExpectations(timeout: 2.0)
        XCTAssertTrue((delegate as! SpyAuthDelegate).didAuthSuccess)
    }
   
}




//// Minimal login view sink to capture ContactInfo assignment
//@objcMembers
//final class LoginViewController: UIViewController {
//    private(set) var lastContactInfo: ContactInfo?
//    func setContactInfo(_ info: ContactInfo) { lastContactInfo = info }
//}
//
//@objcMembers
//final class ContactInfo: NSObject {
//    let title: String
//    let message: String
//    let username: String?
//    
//    init(title: String, andMessage msg: String) {
//        self.title = title
//        self.message = msg
//    }
//    
//    convenience init(title: String, andMessage msg: String, andDetailedInfo: String?) {
//        self.init(title: title, andMessage: msg)
//    }
//}
