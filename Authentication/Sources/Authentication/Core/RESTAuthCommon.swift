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
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.httpBody = jsonData
            req.timeoutInterval = timeout
            
            // Default headers
            var merged = [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
            
            // Merge/override with caller-provided headers
            for (k, v) in headers { merged[k] = v }
            for (k,v) in merged { req.setValue(v, forHTTPHeaderField: k) }
            
            // Build session with explicit timeouts
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = timeout
            config.timeoutIntervalForResource = timeout
            let session = URLSession(configuration: config)
            
            let (data, response) = try await session.data(for: req)
            
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // Important: we do NOT throw on non-2xx here.
            // Error mapping happens at a higher layer (HTTPErrorMapper).
            return (http.statusCode, data)
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
    }
}

typealias HTTP = RESTAuthCommon.HTTP
    
    
extension Dictionary where Key == AnyHashable, Value == Any {
    func string(_ key: String) -> String? { self[key] as? String }
}
