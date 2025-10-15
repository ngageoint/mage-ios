//
//  KeychainAuthStore.swift
//  MAGE
//
//  Created by Brent Michalski on 9/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication

struct KeychainAuthStore: AuthStore {
    func hasStoredPassword() -> Bool {
        StoredPassword.retrieveStoredPassword() != nil
    }
}
