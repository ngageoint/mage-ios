//
//  UserDefaults+Flags.swift
//  MAGE
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let authNextGenEnabled = "authNextGenEnabled"
    }
    var authNextGenEnabled: Bool {
        get { bool(forKey: Keys.authNextGenEnabled) }
        set { set(newValue, forKey: Keys.authNextGenEnabled) }
    }
}
