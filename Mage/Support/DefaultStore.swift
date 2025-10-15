//
//  DefaultStore.swift
//  Authentication
//
//  Created by Brent Michalski on 9/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol DefaultsStore: AnyObject {
    var baseServerUrl: String? { get set }
    var serverMajorVersion: Int { get set }
    var serverMinorVersion: Int { get set }
    var serverMicroVersion: Int { get set }
    var authenticationStrategies: [String: [AnyHashable: Any]]? { get set }
    var serverAuthenticationStrategies: [String: [AnyHashable: Any]]? { get set }
}

// MARK: Production wrapper (UserDefaults.standard)
final class SystemDefaults: DefaultsStore {
    private let systemDefaults: UserDefaults
    
    init(_ u: UserDefaults = .standard) { self.systemDefaults = u }
    
    var baseServerUrl: String? {
        get { systemDefaults.string(forKey: "baseServerUrl") }
        set { systemDefaults.set(newValue, forKey: "baseServerUrl") }
    }

    var serverMajorVersion: Int {
        get { systemDefaults.integer(forKey: "serverMajorVersion") }
        set { systemDefaults.set(newValue, forKey: "serverMajorVersion") }
    }

    var serverMinorVersion: Int {
        get { systemDefaults.integer(forKey: "serverMinorVersion") }
        set { systemDefaults.set(newValue, forKey: "serverMinorVersion") }
    }

    var serverMicroVersion: Int {
        get { systemDefaults.integer(forKey: "serverMicroVersion") }
        set { systemDefaults.set(newValue, forKey: "serverMicroVersion") }
    }

    var authenticationStrategies: [String: [AnyHashable: Any]]? {
        get { systemDefaults.dictionary(forKey: "authenticationStrategies") as? [String: [AnyHashable: Any]] }
        set { systemDefaults.set(newValue, forKey: "authenticationStrategies") }
    }
    
    var serverAuthenticationStrategies: [String : [AnyHashable : Any]]? {
        get { systemDefaults.dictionary(forKey: "serverAuthenticationStrategies") as? [String : [AnyHashable : Any]] }
        set { systemDefaults.set(newValue, forKey: "serverAuthenticationStrategies") }
    }
}

// MARK: In-memory mock for Previews/Tests
final class InMemoryDefaults: DefaultsStore {
    var baseServerUrl: String?
    var serverMajorVersion: Int = 0
    var serverMinorVersion: Int = 0
    var serverMicroVersion: Int = 0
    var authenticationStrategies: [String: [AnyHashable: Any]]?
    var serverAuthenticationStrategies: [String: [AnyHashable: Any]]?
}
