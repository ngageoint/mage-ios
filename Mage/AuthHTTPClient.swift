//
//  AuthHTTPClient.swift
//  MAGE
//
//  Created by Brent Michalski on 10/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public protocol NetworkPerforming {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionNetworker: NetworkPerforming {
    public let session: URLSession
    public init(session: URLSession = .shared) { self.session = session }
    
    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}
