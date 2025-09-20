//
//  HTTPErrorMapper.swift
//  Authentication
//
//  Created by Brent Michalski on 9/19/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum HTTPErrorMapper {
    static func bestMessage(from json: [String: Any]?) -> String? {
        guard let json else { return nil }
        
        if let s = json["message"] as? String { return s }
        if let s = json["error"]   as? String { return s }
        
        if let errors = json["errors"] as? [String: Any] {
            for v in errors.values {
                if let s = v as? String { return s }
                if let arr = v as? [String], let s = arr.first { return s }
            }
        }
        return nil
    }
    
    static func bestMessage(from data: Data?) -> String? {
        guard let d = data, !d.isEmpty else { return nil }
        if let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
            return bestMessage(from: json)
        }
        return String(data: d, encoding: .utf8)
    }
    
    static func retryAfterSeconds(from headers: [AnyHashable: Any]) -> Int? {
        for (k, v) in headers {
            guard let key = k as? String, key.caseInsensitiveCompare("Retry-After") == .orderedSame else { continue }
            if let s = v as? String, let i = Int(s.trimmingCharacters(in: .whitespaces)) { return i }
            if let n = v as? NSNumber { return n.intValue }
        }
        return nil
    }
    
    /// Returns nil for success (2xx), otherwist an AuthError
    public static func map(status: Int,
                    headers: [AnyHashable: Any],
                    bodyData: Data?) -> AuthError? {
        switch status {
        case 200...299:
            return nil
            
        case 401, 403:
            return .unauthorized
            
        case 423:
            return .accountDisabled
            
        case 429:
            return .rateLimited(retryAfterSeconds: retryAfterSeconds(from: headers))
            
        case 400, 422:
            let msgLower = bestMessage(from: bodyData)?.lowercased()
            if let m = msgLower, (m.contains("credential") || m.contains("password")) {
                return .invalidCredentials
            }
            if let m = msgLower, (m.contains("disabled") || m.contains("locked") || m.contains("inactive")) {
                return .accountDisabled
            }
            return .invalidInput(message: bestMessage(from: bodyData))
            
        case 500...599:
            return .server(status: status, message: bestMessage(from: bodyData))
            
        default:
            return .server(status: status, message: bestMessage(from: bodyData))
        }
    }
}
