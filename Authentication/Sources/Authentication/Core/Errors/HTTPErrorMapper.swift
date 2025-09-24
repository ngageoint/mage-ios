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
        
        if let messageString = json["message"] as? String { return messageString }
        if let errorString = json["error"]   as? String { return errorString }
        
        if let errors = json["errors"] as? [String: Any] {
            for value in errors.values {
                if let valueString = value as? String { return valueString }
                if let valueArray = value as? [String], let valueString = valueArray.first { return valueString }
            }
        }
        return nil
    }
    
    static func bestMessage(from data: Data?) -> String? {
        guard let messageData = data, !messageData.isEmpty else { return nil }
        if let json = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any] {
            return bestMessage(from: json)
        }
        return String(data: messageData, encoding: .utf8)
    }
    
    static func retryAfterSeconds(from headers: [AnyHashable: Any]) -> Int? {
        for (k, value) in headers {
            guard let key = k as? String, key.caseInsensitiveCompare("Retry-After") == .orderedSame else { continue }
            if let stringValue = value as? String, let i = Int(stringValue.trimmingCharacters(in: .whitespaces)) { return i }
            if let numberValue = value as? NSNumber { return numberValue.intValue }
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
            let messageLowerCased = bestMessage(from: bodyData)?.lowercased()
            if let message = messageLowerCased, (message.contains("credential") || message.contains("password")) {
                return .invalidCredentials
            }
            if let message = messageLowerCased, (message.contains("disabled") || message.contains("locked") || m.contains("inactive")) {
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
