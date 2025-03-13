//
//  UserDefaults+Extensions.swift
//  MAGE
//
//  Created by Brent Michalski on 3/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation

extension UserDefaults {
    
    /// Prints all stored key-value pairs in UserDefaults.standard
    /// - Parameter title: An optional title to display within the separator lines.
    func printContents(title: String = "") {
        let baseSeparator = "--------------------"
        let separator = title.isEmpty ? "\(baseSeparator) \(baseSeparator)" : "\(baseSeparator) \(title) \(baseSeparator)"
        
        print("\n\(separator)")
        
        let dictionary = dictionaryRepresentation()
        
        if dictionary.isEmpty {
            print("🛑 UserDefaults is empty.")
        } else {
            print("🔍 Current UserDefaults Contents:")
            for (key, value) in dictionary {
                print("\(key): \(value)")
            }
        }
        
        print(separator, "\n")
    }
    
    /// Completely clears all stored data in `UserDefaults.standard`
    func clearAll() {
        for key in dictionaryRepresentation().keys {
//            print("Key: \(key)")
            removeObject(forKey: key)
        }
        synchronize() // Ensures changes are committed immediately
        print("🚮 UserDefaults has been fully cleared!")
    }
    
    static func resetDefaults() {
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
    }
}
