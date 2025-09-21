//
//  RESTAuthCommon.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum RESTAuthCommon {
    enum HTTP {
        @discardableResult
        static func postJSONAsync(
            url: URL,
            headers: [String: String] = [:],
            body: [String: Any],
            timeout: TimeInterval = 30
        ) async throws -> (status: Int, data: Data) {
            
            let (status, data, _) = try await postJSONWithHeadersAsync(
                url: url, headers: headers, body: body, timeout: timeout
            )
            return (status, data)
        }
        
        static func postJSON(
            _ url: URL,
            body: [String: Any],
            completion: @escaping (Int, Data?, Error?) -> Void
        ) {
            Task {
                do {
                    let (status, data) = try await postJSONAsync(
                        url: url,
                        headers: [:],
                        body: body,
                        timeout: 30
                    )
                    completion(status, data, nil)
                } catch {
                    completion(-1, nil, error)
                }
            }
        }
        
        @discardableResult
        static func postJSONWithHeadersAsync(
            url: URL,
            headers: [String: String] = [:],
            body: [String: Any],
            timeout: TimeInterval = 30
        ) async throws -> (status: Int, data: Data, headers: [AnyHashable: Any]) {
            
            // Encode body
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            
            // Build request
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.httpBody = jsonData
            req.timeoutInterval = timeout
            
            // Merge headers (defaults + caller)
            var merged = [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
            headers.forEach { merged[$0.key] = $0.value }
            merged.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            // Session with explicit timeouts
            let cfg = URLSessionConfiguration.ephemeral
            cfg.timeoutIntervalForRequest = timeout
            cfg.timeoutIntervalForResource = timeout
            let session = URLSession(configuration: cfg)
            
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            
            // Do not throw on non-2xx here; mapping happens above this layer
            return (http.statusCode, data, http.allHeaderFields)
        }
    }
}

typealias HTTP = RESTAuthCommon.HTTP
    
    
extension Dictionary where Key == AnyHashable, Value == Any {
    func string(_ key: String) -> String? { self[key] as? String }
}
