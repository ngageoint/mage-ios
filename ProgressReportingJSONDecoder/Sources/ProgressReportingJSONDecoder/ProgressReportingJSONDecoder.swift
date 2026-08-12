// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Alamofire

// MARK: - ProgressReportingJSONDecoder

/// A drop-in replacement for `JSONDecoder` that conforms to Alamofire's
/// `ResponseDecoder` and reports per-element progress when decoding a
/// top-level JSON array.
///
/// Usage:
/// ```swift
/// let decoder = ProgressReportingJSONDecoder { progress in
///     print("Decoded \(progress.completed) / \(progress.total)")
/// }
/// let items = try await session
///     .request(url)
///     .serializingDecodable([MyDTO].self, decoder: decoder)
///     .value
/// ```
public final class ProgressReportingJSONDecoder: DataDecoder {
    
    // MARK: Properties
    
    private let underlying: JSONDecoder
    private let onProgress: @Sendable (DecodingProgress) -> Void
    
    // MARK: Init
    
    /// - Parameters:
    ///   - underlying: The `JSONDecoder` to use for actual JSON parsing.
    ///                 Defaults to a fresh instance; configure date strategies etc. here.
    ///   - onProgress: Called on the **calling thread** after each element in the
    ///                 top-level array is decoded.  Also called once when the array
    ///                 count becomes known (completed = 0).
    public init(
        underlying: JSONDecoder = JSONDecoder(),
        onProgress: @Sendable @escaping (DecodingProgress) -> Void
    ) {
        self.underlying = underlying
        self.onProgress = onProgress
    }
    
    // MARK: ResponseDecoder
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // Only inject progress tracking when T is an Array.
        // For non-array types we fall straight through to the standard decoder.
        if let arrayType = T.self as? AnyProgressTrackableArray.Type {
            return try arrayType.decode(
                from: data,
                using: underlying,
                onProgress: onProgress
            ) as! T                         // safe: arrayType.decode returns T
        }
        return try underlying.decode(type, from: data)
    }
}

// MARK: - Decoder passthrough with date / key strategies

extension ProgressReportingJSONDecoder {
    /// Exposes the underlying decoder so callers can configure
    /// `dateDecodingStrategy`, `keyDecodingStrategy`, etc.
    public var jsonDecoder: JSONDecoder { underlying }
}
