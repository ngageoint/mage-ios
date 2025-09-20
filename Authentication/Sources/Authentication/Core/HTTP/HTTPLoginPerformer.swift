//
//  HTTPLoginPerformer.swift
//  Authentication
//
//  Created by Brent Michalski on 9/19/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public struct HTTPLoginPerformer {
    
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
    
//    private static func bestMessage(from json: [String: Any]?) -> String? {
//        guard let json else { return nil }
//        if let msg = json["message"] as? String { return msg }
//        if let err = json["error"] as? String { return err }
//        if let errors = json["errors"] as? [String: Any] {
//            // Pull the first error string we can find
//            for value in errors.values {
//                if let s = value as? String { return s }
//                if let arr = value as? [String], let s = arr.first { return s }
//            }
//        }
//        return nil
//    }
//    
//    private static func retryAfterSeconds(from headers: [AnyHashable: Any]) -> Int? {
//        for (k, v) in headers {
//            guard let key = k as? String, key.caseInsensitiveCompare( "Retry-After" ) == .orderedSame else { continue }
//            if let s = v as? String, let i = Int(s.trimmingCharacters(in: .whitespaces)) { return i }
//            if let n = v as? NSNumber { return n.intValue }
//        }
//        return nil
//    }
    
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
