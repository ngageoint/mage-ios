//
//  AuthContractHarnessTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class AuthContractHarnessTests: XCTestCase {
    func testHarness_ComparesStatusAndBody() async {
        let map: [String:(Int, StubPerformer.Fixture)] = [
            "POST /api/login": (200, .login_ok),
            "POST /api/users": (409, .signup_confilct),
            "GET /api/captcha?u=": (401, .captcha_401),
            "PUT /api/users/myself/password": (200, .change_ok),
        ]
        let legacy = StubPerformer(mapping: map)
        let modern = StubPerformer(mapping: map)
        
        // Sample endpoints
        let endpoints: [AuthEndpoint] = [
            .loginLocal(username: "a", password: "b"),
            .signup(displayName: "d", username: "u", password: "p", email: nil, captcha: nil),
            .captcha(username: nil),
            .changePassword(current: "x", new: "y", confirm: "y"),
        ]
        
        for ep in endpoints {
            let l = await legacy.perform(ep)
            let r = await modern.perform(ep)
            AssertEqualContract(l, r)
        }
    }
}
