//
//  LegacyHarnessTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class LegacyHarnessTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLStubRegistry.shared.reset()
        
        // Load fixtures for each route we need
        func data(_ name: StubPerformer.Fixture) -> Data {
            let b = Bundle(for: LegacyHarnessTests.self)
            return try! Data(contentsOf: b.url(forResource: name.rawValue, withExtension: nil)!)
        }
        
        URLStubRegistry.shared.set("POST", "/api/login", status: 200, body: data(.login_ok))
        URLStubRegistry.shared.set("POST", "/api/users", status: 409, body: data(.signup_conflict))
        URLStubRegistry.shared.set("GET", "/api/captcha?u=", status: 401, body: data(.captcha_401))
        URLStubRegistry.shared.set("PUT", "/api/users/myself/password", status: 200, body: data(.change_ok))
    }
    
    override func tearDown() {
        URLStubRegistry.shared.reset()
        super.tearDown()
    }
    
    func test_Legacy_vs_Fixtures_match() async {
        let legacy = LegacyAuthHTTPPerformer(baseURL: URL(string: "https://stubbed.mage")!)
        let expected = StubPerformer(mapping: [
            "POST /api/login": (200, .login_ok),
            "POST /api/users": (409, .signup_conflict),
            "GET /api/captcha?u=": (401, .captcha_401),
            "PUT /api/users/myself/password": (200, .change_ok),
        ])
        
        let endpoints: [AuthEndpoint] = [
            .loginLocal(username: "a", password: "b"),
            .signup(displayName: "d", username: "u", password: "p", email: nil, captcha: nil),
            .captcha(username: nil),
            .changePassword(current: "x", new: "y", confirm: "y"),
        ]
        
        for ep in endpoints {
            let l = await legacy.perform(ep)
            let r = await expected.perform(ep)
            AssertEqualContract(l, r) // compares status + normalized JSON
        }
    }
}
