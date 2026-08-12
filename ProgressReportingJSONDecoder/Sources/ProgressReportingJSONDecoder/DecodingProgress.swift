//
//  DecodingProgress.swift
//  ProgressReportingJSONDecoder
//
//  Created by Daniel Barela on 7/21/26.
//

public struct DecodingProgress: Sendable {
    /// Number of array elements fully decoded so far.
    public let completed: Int
    /// Total number of elements in the top-level array, once known.
    /// Will be 0 until the array container has been opened.
    public let total: Int
}
