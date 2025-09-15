//
//  MageDependencyBootstrap.swift
//  MAGE
//
//  Created by Brent Michalski on 9/8/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Authentication

@objc public final class MageDependencyBootstrap: NSObject {
    @objc public static func configure() {
        print("\n---------------------------------------------")
        print("ZZZ - MageDependencyBootstrap.configure() called.")
        print("---------------------------------------------\n")
        // the real concrete implementation that calls MageAuthAPI / AFNetworking
        AuthDependencies.shared.authService = MageAuthServiceImpl()
        AuthDependencies.shared.sessionStore = MageSessionStore.shared
    }
}
