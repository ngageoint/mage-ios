//
//  MageDependencyBootstrap.swift
//  MAGE
//
//  Created by Brent Michalski on 9/8/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication

@objc public final class MageDependencyBootstrap: NSObject {
    /// Call from AppDelegate early in launch
    @objc public static func configure() {
        // 1) Stores used by the new auth stack
        AuthDependencies.shared.sessionStore = MageSessionStore.shared
        
        // 2) Lazily configure the concrete AuthService if we already have a base URL
        // (Or it the user sets/changes the server)
        if let base = MageServer.baseURL() {
            AuthDependencies.shared.configureAuthServiceIfNeeded(baseURL: base, session: .shared)
        }
        
    }
}
