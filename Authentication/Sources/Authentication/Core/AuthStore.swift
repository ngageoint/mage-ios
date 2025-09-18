//
//  AuthStore.swift
//  Authentication
//
//  Created by Brent Michalski on 9/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public protocol AuthStore {
    init()
    func hasStoredPassword() -> Bool
}

public protocol OfflineCredentialStore: AnyObject {
    func loadOfflineSecret() -> String?
}

public struct AuthFactoryDeps {
    public var offlineStore: OfflineCredentialStore?
    public init(offlineStore: OfflineCredentialStore? = nil) { self.offlineStore = offlineStore }
}
