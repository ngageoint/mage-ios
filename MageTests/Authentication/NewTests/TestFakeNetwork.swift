//
//  TestFakeNetwork.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
@testable import MAGE

/// Route matcher + responder used by the fake network
public struct TestRoute {
    public let matches: (URLRequest) -> Bool
    public let respond: (URLRequest) -> (Data, HTTPURLResponse)
    
    public init(matches: @escaping (URLRequest) -> Bool,
                respond: @escaping (URLRequest) -> (Data, HTTPURLResponse)) {
        self.matches = matches
        self.respond = respond
    }
}

/// Test-only implementation of `NetworkPerforming`
/// It returns canned responses for requests that match a provided route
public final class TestFakeNetwork: NetworkPerforming {
    private let routes: [TestRoute]
    
    public init(routes: [TestRoute]) {
        self.routes = routes
    }
    
    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        if let route = routes.first(where: { route in route.matches(request) }) {
            return route.respond(request)
        }
        
        // Unmatched requests fail loudly so tests are deterministic
        throw URLError(.badURL)
    }
}


