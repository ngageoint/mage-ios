//
//  Date.swift
//  MAGE
//
//  Created by Daniel Benner on 6/30/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

extension Date.ISO8601FormatStyle {
    /// A shared, pre-configured ISO8601FormatStyle for common internet date-time with fractional seconds.
    fileprivate static let gmtZero = Date.ISO8601FormatStyle(
        dateSeparator: .dash,
        dateTimeSeparator: .standard,
        timeSeparator: .colon,
        timeZoneSeparator: .omitted, // skip colon in Timezone (try using .current to see diff)
        includingFractionalSeconds: true,
        timeZone: .gmt
    )
    
    /// Format date using TimeZone(secondsFromGMT: 0)
    static func gmtZeroString(from date:Date) -> String {
        return date.formatted(gmtZero)
    }
    
    /// Format string to Date using TimeZone(secondsFromGMT: 0)
    static func gmtZeroDate(from dateString:String) -> Date? {
        return try? Date(dateString, strategy: gmtZero)
    }
}
