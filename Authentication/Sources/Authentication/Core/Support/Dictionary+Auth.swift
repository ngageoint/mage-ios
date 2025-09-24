//
//  Dictionary+Auth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/22/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public extension Dictionary where Key == AnyHashable, Value == Any {
    /// Returns the value for `key` cast as String, or nil.
    func string(_ key: String) -> String? { self[key] as? String }
    
    /// Other helpers
    func bool(_ key: String) -> Bool? { self[key] as? Bool }
    
    func int(_ key: String) -> Int? {
        if let number = self[key] as? Int { return number }
        if let string = self[key] as? String, let i = Int(string) { return i }
        return nil
    }
}
