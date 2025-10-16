//
//  JSONNormalize.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

/// Canonicalizes JSON so two semantically-equal payloads compare equal:
/// - removes null values **inside dictionaries**
/// - keeps nulls **inside arrays** (preserves array length/positions)
/// - re-encodes with sorted keys for deterministic output

enum JSONNormalize {
    /// Convert raw Data -> canonical Data (or nil if input wasn't valid JSON)
    static func canonicalData(_ data: Data?) -> Data? {
        guard
            let data,
            let jsonObject = try? JSONSerialization.jsonObject(with: data)
        else { return nil }
        
        let normalized = normalize(jsonObject)
        return try? JSONSerialization.data(withJSONObject: normalized, options: [.sortedKeys])
    }
    
    /// Convenience: canonical body as a UTF-8 string ("" if input wasn't JSON)
    static func canonicalizeString(_ data: Data?) -> String {
        guard let canonical = canonicalData(data) else { return "" }
        return String(data: canonical, encoding: .utf8) ?? ""
    }
    
    /// Recursively normalize any JSON fragment.
    ///
    /// - Dictionaries:
    ///   * normalize each value
    ///   * drop keys whose normalized value is `NSNull`
    /// - Arrays:
    ///   * normalize each element
    ///   * keep `NSNull` to preserve positions
    /// - Primitives (String/Number/Bool):
    ///   * return as-is
    /// - NSNull:
    ///   * returned as NSNull (caller decides whether to keep/drop)
    private static func normalize(_ fragment: Any) -> Any {
        switch fragment {
            // Object / dictionary
        case let object as [String: Any]:
            var normalizedObject: [String: Any] = [:]
            
            
            for(rawKey, rawValue) in object {
                let normalizedValue = normalize(rawValue)
                
                // Drop nulls inside dictionaries to avoid meaningless diffs
                if !(normalizedValue is NSNull) {
                    normalizedObject[rawKey] = normalizedValue
                }
            }
            return normalizedObject
            
            // Array
        case let array as [Any]:
            // Keep NSNulls to preserve array shape/indices
            return array.map { normalize($0) }
            
            // Explicit JSON null
        case is NSNull:
            return NSNull()
            
            // Primitives (String, Number, Bool) - pass through
        default:
            return fragment
        }
    }
    
}

