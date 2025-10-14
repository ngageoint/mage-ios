//
//  ServerInfoService.swift
//  MAGE
//
//  Created by Brent Michalski on 10/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public final class ServerInfoService {
    private let base: URL
    private let net: NetworkPerforming
   
    public init(baseURL: URL, net: NetworkPerforming = URLSessionNetworker()) {
        self.base = baseURL
        self.net = net
    }
    
    /// Fetches `server.json` from `/api`(falls back to `/api/server`) and
    /// returns a dictionary keyed by strategy identifier.
    public func fetchServerModules() async throws -> [String: [String: Any]] {
        let candidates = [
            base.appendingPathComponent("api"),
            base.appendingPathComponent("api/server")
        ]
        
        var lastErr: Error?
        
        for url in candidates {
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.addValue("application/json", forHTTPHeaderField: "Accept")
            req.timeoutInterval = 15
            
            do {
                let (data, resp) = try await net.data(for: req)
                guard (200..<300).contains(resp.statusCode) else { continue }
                let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                let arr = obj["authenticationStrategies"] as? [[String: Any]] ?? []
                var modules: [String: [String: Any]] = [:]
                
                for strategy in arr {
                    if let id = strategy["identifier"] as? String {
                        modules[id] = strategy
                    }
                }
                return modules
            } catch {
                lastErr = error
            }
        }
        throw lastErr ?? URLError(.badServerResponse)
    }
}
