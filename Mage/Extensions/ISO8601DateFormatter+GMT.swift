//
//  ISO8601DateFormatter+GMT.swift
//  MAGE
//
//  Created by Daniel Benner on 6/19/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension ISO8601DateFormatter {
    fileprivate static let GMTzero = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
        return formatter
    }()
    
    /// Format date using TimeZone(secondsFromGMT: 0)
    static func gmtZeroString(from date:Date) -> String {
        return GMTzero.string(from: date)
    }
    
    /// Format string to Date using TimeZone(secondsFromGMT: 0)
    static func gmtZeroDate(from date:String) -> Date? {
        return GMTzero.date(from: date)
    }
}
