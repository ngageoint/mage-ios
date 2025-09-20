//
//  MageSessionStore.swift
//  MAGE
//
//  Created by Brent Michalski on 9/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Authentication

public final class MageSessionStore: SessionStore {
    public static let shared = MageSessionStore()
    private init() {}
    
    public private(set) var current: AuthSession?
    
    public func set(_ session: AuthSession?) async {
        current = session
        // TODO: Persist if needed to Keychain/UserDefaults
    }
    
    public func clear() async {
        current = nil
        // TODO: Clear persisted state
    }
}
