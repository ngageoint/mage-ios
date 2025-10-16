//
//  LegacyAuthHTTPPerformer.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

final class LegacyAuthHTTPPerformer: LegacyAuthPerformer {
    private let baseURL: URL
    
    // Build a session from `.default` AFTER tests call `SessionConfigSwizzle.install()`
    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        var classes = cfg.protocolClasses ?? []
        // Put your TestURLProtocol first so it intercepts.
        if classes.first(where: { $0 == TestURLProtocol.self }) == nil {
            classes.insert(TestURLProtocol.self, at: 0)
        }
        cfg.protocolClasses = classes
        return URLSession(configuration: cfg)
    }()
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func perform(_ endpoint: AuthEndpoint) async -> HTTPResponse {
        // Construct URLRequest consistent with legacy code, or invoke the same entry points
        // If you have a legacy “login” call, call it here. Otherwise, fall back to a direct URLRequest.
        let req = endpoint.request
        
        guard let url = URL(string: baseURL.absoluteString + req.path) else {
            return HTTPResponse(status: 599, body: nil, headers: [:])
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = req.method
        urlRequest.httpBody = req.body
        
        for (key, value) in req.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, resp) = try await session.data(for: urlRequest)
            let http = resp as! HTTPURLResponse
            return HTTPResponse(status: http.statusCode,
                                body: data,
                                headers: http.allHeaderFields as? [String: String] ?? [:])
        } catch {
            // Transport error → synthetic 599 so harness can still compare
            return HTTPResponse(status: 599, body: nil, headers: [:])
        }
    }
}
