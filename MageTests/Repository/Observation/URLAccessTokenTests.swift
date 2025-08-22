//
//  URLAccessTokenTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class URLAccessTokenTests: XCTestCase {
    func testTokenizeAppendsAccessToken() {
        let base = URL(string: "https://example.com/video.mp4")!
        let tokenized = AccessTokenURL.tokenized(base, token: "FAKE")
        
        let comps = URLComponents(url: tokenized, resolvingAgainstBaseURL: false)!
        XCTAssertTrue((comps.queryItems ?? []).contains(.init(name: "access_token", value: "FAKE")))
        
        let hasAccessToken = (comps.queryItems ?? []).contains(where: { $0.name == "access_token" && $0.value == "FAKE" })
        XCTAssertTrue(hasAccessToken)
    }
}
