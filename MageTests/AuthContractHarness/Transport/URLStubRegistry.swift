//
//  URLStubRegistry.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

final class URLStubRegistry {
    static let shared = URLStubRegistry()
    private let lock = NSLock()
    private var stubs: [String: (status: Int, headers: [String:String], body: Data?)] = [:]
    
    func set(_ method: String, _ path: String, status: Int, headers: [String:String] = [:], body: Data?) {
        lock.lock(); defer { lock.unlock() }
        stubs[key(method, path)] = (status, headers, body)
    }
    
    func response(for request: URLRequest) -> (Int, [String:String], Data?)? {
        guard let url = request.url else { return nil }
        let path = url.path + (url.query.map { "?\($0)" } ?? "")
        return stubs[key(request.httpMethod ?? "GET", path)]
    }
    
    func reset() {
        lock.lock()
        stubs.removeAll()
        lock.unlock()
    }
    
    private func key(_ method: String, _ path: String) -> String { "\(method.uppercased()) \(path)" }
}
