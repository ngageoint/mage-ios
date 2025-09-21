//
//  HTTPLoginPerformer.swift
//  Authentication
//
//  Created by Brent Michalski on 9/19/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

// MARK: - Protocol

public protocol HTTPPerforming: Sendable {
    @discardableResult
    func postJSON(
        url: URL,
        headers: [String: String],
        body: [String: Any],
        timeout: TimeInterval
    ) async throws -> (status: Int, data: Data)
    
}


// MARK: - Concrete Performer (Adapter)

public final class HTTPLoginPerformer: HTTPPerforming {
    public init() {}
    
    @discardableResult
    public func postJSON(
url: URL,
    headers: [String: String] = [:],
    body: [String: Any],
    timeout: TimeInterval = 30
    ) async throws -> (status: Int, data: Data) {
        // NOTE: This keeps current behavior by delegating to the legacy helper.
        return try await RESTAuthCommon.HTTP.postJSONAsync(
            url: url,
            headers: headers,
            body: body,
            timeout: timeout
        )
    }
    
    public struct Request {
        public var baseURL: URL
        public var path: String
        public var jsonBody: [String: Any]
        public var headers: [String: String]
        public var timeout: TimeInterval
        
        public init(
            baseURL: URL,
            path: String,
            jsonBody: [String: Any],
            headers: [String: String] = [:],
            timeout: TimeInterval = 30
        ) {
            self.baseURL = baseURL
            self.path = path
            self.jsonBody = jsonBody
            self.headers = headers
            self.timeout = timeout
        }
    }
    
    public struct Response {
        public let statusCode: Int
        public let bodyJSON: [String: Any]?
    }
    
    public static func perform(_ req: Request,
                               session: URLSession = .shared,
                               completion: @escaping (Result<Response, AuthError>) -> Void) {
        guard let url = URL(string: req.path, relativeTo: req.baseURL) else {
            completion(.failure(.configuration))
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: req.timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        for (k, v) in req.headers { request.setValue(v, forHTTPHeaderField: k) }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: req.jsonBody, options: [])
        } catch {
            completion(.failure(.configuration))
            return
        }
        
        let task = session.dataTask(with: request) { data, resp, err in
            if let err = err as NSError? {
                if err.domain == NSURLErrorDomain, err.code == NSURLErrorCancelled {
                    completion(.failure(.cancelled))
                    return
                } else {
                    completion(.failure(.network(underlying: err)))
                    return
                }
            }
            
            guard let http = resp as? HTTPURLResponse else {
                completion(.failure(.malformedResponse))
                return
            }
            
            if let mapped = HTTPErrorMapper.map(status: http.statusCode, headers: http.allHeaderFields, bodyData: data) {
                completion(.failure(mapped))
                return
            }
            
            let bodyJSON: [String: Any]?
            if let data, !data.isEmpty {
                bodyJSON = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            } else {
                bodyJSON = nil
            }
            
            completion(.success(Response(statusCode: http.statusCode, bodyJSON: bodyJSON)))
        }
        task.resume()
    }
    
    public static func perform(_ req: Request,
                               session: URLSession = .shared) async -> Result<Response, AuthError> {
        await withCheckedContinuation { cont in
            perform(req, session: session) { result in
                cont.resume(returning: result)
            }
        }
    }
}
