//
//  AuthStore.swift
//  Authentication
//
//  Created by Brent Michalski on 9/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

/// Abstraction OfflineAuth uses to decide if offline is possible.
public protocol AuthStore {
    func hasStoredPassword() -> Bool
}

/// Framework-default that never allows offline.
/// (The app will inject a real store.)
struct NullAuthStore: AuthStore {
    func hasStoredPassword() -> Bool { false }
}
