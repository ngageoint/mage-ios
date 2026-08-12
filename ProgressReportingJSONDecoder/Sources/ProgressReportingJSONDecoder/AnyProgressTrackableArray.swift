//
//  AnyProgressTrackableArray.swift
//  ProgressReportingJSONDecoder
//
//

import Foundation

// Protocol trick: lets us call a generic static method without knowing Element.
protocol AnyProgressTrackableArray {
    static func decode(
        from data: Data,
        using decoder: JSONDecoder,
        onProgress: @escaping (DecodingProgress) -> Void
    ) throws -> Self
}

extension Array: AnyProgressTrackableArray where Element: Decodable {
    static func decode(
        from data: Data,
        using decoder: JSONDecoder,
        onProgress: @escaping (DecodingProgress) -> Void
    ) throws -> Self {
        // Parse the JSON once into a raw [Any] so we know the count up front,
        // then re-decode each element individually so we can report progress.
        //
        // This two-pass approach keeps element decoding 100 % faithful to the
        // caller-configured JSONDecoder (date strategies, key strategies, etc.)
        // while giving us the element boundary information we need.
        
        guard let rawArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            // Fallback: not an array-of-objects — decode normally without progress.
            return try decoder.decode([Element].self, from: data)
        }
        
        let total = rawArray.count
        onProgress(DecodingProgress(completed: 0, total: total))
        
        var results: [Element] = []
        results.reserveCapacity(total)
        
        for (index, rawObject) in rawArray.enumerated() {
            let elementData = try JSONSerialization.data(withJSONObject: rawObject)
            let element = try decoder.decode(Element.self, from: elementData)
            results.append(element)
            onProgress(DecodingProgress(completed: index + 1, total: total))
        }
        
        return results
    }
}
