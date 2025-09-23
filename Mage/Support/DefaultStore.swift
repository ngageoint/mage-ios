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
    private let u: UserDefaults
    
    init(_ u: UserDefaults = .standard) { self.u = u }
    
    var baseServerUrl: String? {
        get { u.string(forKey: "baseServerUrl") }
        set { u.set(newValue, forKey: "baseServerUrl") }
    }

    var serverMajorVersion: Int {
        get { u.integer(forKey: "serverMajorVersion") }
        set { u.set(newValue, forKey: "serverMajorVersion") }
    }

    var serverMinorVersion: Int {
        get { u.integer(forKey: "serverMinorVersion") }
        set { u.set(newValue, forKey: "serverMinorVersion") }
    }

    var serverMicroVersion: Int {
        get { u.integer(forKey: "serverMicroVersion") }
        set { u.set(newValue, forKey: "serverMicroVersion") }
    }

    var authenticationStrategies: [String: [AnyHashable: Any]]? {
        get { u.dictionary(forKey: "authenticationStrategies") as? [String: [AnyHashable: Any]] }
        set { u.set(newValue, forKey: "authenticationStrategies") }
    }
    
    var serverAuthenticationStrategies: [String : [AnyHashable : Any]]? {
        get { u.dictionary(forKey: "serverAuthenticationStrategies") as? [String : [AnyHashable : Any]] }
        set { u.set(newValue, forKey: "serverAuthenticationStrategies") }
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
