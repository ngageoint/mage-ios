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
            let (status, data, _) = try await postJSONWithHeadersAsync(url: url, headers: headers, body: body, timeout: timeout)
            return (status, data)
        }
        
        @available(*, deprecated, message: "Use postJSONWithHeadersAsync via HTTPLoginPerformer.postJSONWithHeaders(...) instead.")
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
            // Forward to the single implementation
            return try await HTTPLoginPerformer().postJSONWithHeaders(url: url, headers: headers, body: body, timeout: timeout)
        }
    }
}

typealias HTTP = RESTAuthCommon.HTTP
