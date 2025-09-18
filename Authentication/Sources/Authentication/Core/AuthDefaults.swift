//
//  AuthDefaults.swift
//  Authentication
//
//  Created by Brent Michalski on 9/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum AuthDefaults {
    private static var d: UserDefaults { .standard }
    
    // MARK: - Server identity
    public static var baseServerUrl: String? {
        get { d.string(forKey: "baseServerUrl") }
        set { d.set(newValue, forKey: "baseServerUrl") }
    }
    
    // MARK: - Server version / compat
    public static var serverMajorVersion: Int {
        get { d.integer(forKey: "serverMajorVersion") }
        set { d.set(newValue, forKey: "serverMajorVersion") }
    }

    public static var serverMinorVersion: Int {
        get { d.integer(forKey: "serverMinorVersion") }
        set { d.set(newValue, forKey: "serverMinorVersion") }
    }

    public static var serverCompatibilities: [[String: Int]]? {
        get { d.array(forKey: "serverCompatibilities") as? [[String: Int]] }
        set { d.set(newValue, forKey: "serverCompatibilities") }
    }
    
    // MARK: - Auth strategies
    public static var authenticationStrategies: [String: [AnyHashable: Any]]? {
        get { d.dictionary(forKey: "authenticationStrategies") as? [String: [AnyHashable: Any]] }
        set { d.set(newValue, forKey: "authenticationStrategies") }
    }
    
    public static var serverAuthenticationStrategies: [String: [AnyHashable: Any]]? {
        get { d.dictionary(forKey: "serverAuthenticationStrategies") as? [String: [AnyHashable: Any]] }
        set { d.set(newValue, forKey: "serverAuthenticationStrategies") }
    }
    
    // MARK: - Last login (used for offline)
    public static var loginParameters: [String: Any]? {
        get { d.dictionary(forKey: "loginParameters") as? [String: [AnyHashable: Any]] }
        set { d.set(newValue, forKey: "loginParameters") }
    }
    
    // MARK: - API flags the auth layer writes
    public static var locationServiceDisabled: Bool {
        get { d.bool(forKey: "locationServiceDisabled") }
        set { d.set(newValue, forKey: "locationServiceDisabled") }
    }
    
    public static var showDisclaimer: Bool {
        get { d.bool(forKey: "showDisclaimer") }
        set { d.set(newValue, forKey: "showDisclaimer") }
    }
    
    public static var disclaimerText: String? {
        get { d.string(forKey: "disclaimerText") }
        set { d.set(newValue, forKey: "disclaimerText") }
    }
    
    public static var disclaimerTitle: String? {
        get { d.string(forKey: "disclaimerTitle") }
        set { d.set(newValue, forKey: "disclaimerTitle") }
    }
    
    // MARK: - Contact info from /api
    public static var contactInfoEmail: String? {
        get { d.string(forKey: "contactInfoEmail") }
        set { d.set(newValue, forKey: "contactInfoEmail") }
    }
    
    public static var contactInfoPhone: String? {
        get { d.string(forKey: "contactInfoPhone") }
        set { d.set(newValue, forKey: "contactInfoPhone") }
    }
    
}

