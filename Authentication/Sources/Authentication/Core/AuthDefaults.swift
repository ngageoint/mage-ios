//
//  AuthDefaults.swift
//  Authentication
//
//  Created by Brent Michalski on 9/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum AuthDefaults {
    private static var authDefaults: UserDefaults { .standard }
    
    // MARK: - Server identity
    public static var baseServerUrl: String? {
        get { authDefaults.string(forKey: "baseServerUrl") }
        set { authDefaults.set(newValue, forKey: "baseServerUrl") }
    }
    
    // MARK: - Server version / compat
    public static var serverMajorVersion: Int {
        get { authDefaults.integer(forKey: "serverMajorVersion") }
        set { authDefaults.set(newValue, forKey: "serverMajorVersion") }
    }

    public static var serverMinorVersion: Int {
        get { authDefaults.integer(forKey: "serverMinorVersion") }
        set { authDefaults.set(newValue, forKey: "serverMinorVersion") }
    }

    public static var serverCompatibilities: [[String: Int]]? {
        get { authDefaults.array(forKey: "serverCompatibilities") as? [[String: Int]] }
        set { authDefaults.set(newValue, forKey: "serverCompatibilities") }
    }
    
    // MARK: - Auth strategies
    public static var authenticationStrategies: [String: [AnyHashable: Any]]? {
        get { authDefaults.dictionary(forKey: "authenticationStrategies") as? [String: [AnyHashable: Any]] }
        set { authDefaults.set(newValue, forKey: "authenticationStrategies") }
    }
    
    public static var serverAuthenticationStrategies: [String: [AnyHashable: Any]]? {
        get { authDefaults.dictionary(forKey: "serverAuthenticationStrategies") as? [String: [AnyHashable: Any]] }
        set { authDefaults.set(newValue, forKey: "serverAuthenticationStrategies") }
    }
    
    // MARK: - Last login (used for offline)
    public static var loginParameters: [String: Any]? {
        get { authDefaults.dictionary(forKey: "loginParameters") as? [String: [AnyHashable: Any]] }
        set { authDefaults.set(newValue, forKey: "loginParameters") }
    }
    
    // MARK: - API flags the auth layer writes
    public static var locationServiceDisabled: Bool {
        get { authDefaults.bool(forKey: "locationServiceDisabled") }
        set { authDefaults.set(newValue, forKey: "locationServiceDisabled") }
    }
    
    public static var showDisclaimer: Bool {
        get { authDefaults.bool(forKey: "showDisclaimer") }
        set { authDefaults.set(newValue, forKey: "showDisclaimer") }
    }
    
    public static var disclaimerText: String? {
        get { authDefaults.string(forKey: "disclaimerText") }
        set { authDefaults.set(newValue, forKey: "disclaimerText") }
    }
    
    public static var disclaimerTitle: String? {
        get { authDefaults.string(forKey: "disclaimerTitle") }
        set { authDefaults.set(newValue, forKey: "disclaimerTitle") }
    }
    
    // MARK: - Contact info from /api
    public static var contactInfoEmail: String? {
        get { authDefaults.string(forKey: "contactInfoEmail") }
        set { authDefaults.set(newValue, forKey: "contactInfoEmail") }
    }
    
    public static var contactInfoPhone: String? {
        get { authDefaults.string(forKey: "contactInfoPhone") }
        set { authDefaults.set(newValue, forKey: "contactInfoPhone") }
    }
    
}

