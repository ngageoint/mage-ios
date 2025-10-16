//
//  AuthServiceFactory.swift
//  Authentication
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum AuthServiceFactory {
    static func make() -> AuthService { NoopAuthService() }
}
