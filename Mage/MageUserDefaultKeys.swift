//
//  MageUserDefaultKeys.swift
//  MAGE
//
//  Created by Daniel Barela on 9/29/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    struct MageServer: MageServerDefaultable {
        private init() { }
        
        enum MageServerDefaultKey: String {
            case baseServerUrl
            case lastName
        }
    }
    
    struct Map: MapDefaultable {
        private init() { }
        
        enum MapDefaultKey: String {
            case mapType
            case showMGRS
        }
    }
    
    struct Authentication: AuthenticationDefaultable {
        private init() { }
        
        enum AuthenticationDefaultKey: String {
            case deviceRegistered
        }
    }
}

protocol KeyNamespaceable { }

extension KeyNamespaceable {
    private static func namespace(_ key: String) -> String {
        return "\(Self.self).\(key)"
    }
    
    static func namespace<T: RawRepresentable>(_ key: T) -> String where T.RawValue == String {
        return namespace(key.rawValue)
    }
}

protocol MageServerDefaultable: KeyNamespaceable {
    associatedtype MageServerDefaultKey: RawRepresentable
}

extension MageServerDefaultable where MageServerDefaultKey.RawValue == String {
    
    static func set(_ string: String, forKey key: MageServerDefaultKey) {
        UserDefaults.standard.set(string, forKey: key.rawValue);//namespace(key))
    }
    
    static func string(forKey key: MageServerDefaultKey) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ integer: Int, forKey key: MageServerDefaultKey) {
        UserDefaults.standard.set(integer, forKey: key.rawValue);//namespace(key))
    }
    
    static func integer(forKey key: MageServerDefaultKey) -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue);//namespace(key))
    }
}

protocol MapDefaultable: KeyNamespaceable {
    associatedtype MapDefaultKey: RawRepresentable
}

extension MapDefaultable where MapDefaultKey.RawValue == String {
    
    static func set(_ string: String, forKey key: MapDefaultKey) {
        UserDefaults.standard.set(string, forKey: key.rawValue);//namespace(key))
    }
    
    static func string(forKey key: MapDefaultKey) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ integer: Int, forKey key: MapDefaultKey) {
        UserDefaults.standard.set(integer, forKey: key.rawValue);//namespace(key))
    }
    
    static func integer(forKey key: MapDefaultKey) -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ bool: Bool, forKey key: MapDefaultKey) {
        UserDefaults.standard.set(bool, forKey: key.rawValue);//namespace(key))
    }
    
    static func bool(forKey key: MapDefaultKey) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue);//namespace(key))
    }
}

protocol AuthenticationDefaultable: KeyNamespaceable {
    associatedtype AuthenticationDefaultKey: RawRepresentable
}

extension AuthenticationDefaultable where AuthenticationDefaultKey.RawValue == String {
    
    static func set(_ string: String, forKey key: AuthenticationDefaultKey) {
        UserDefaults.standard.set(string, forKey: key.rawValue);//namespace(key))
    }
    
    static func string(forKey key: AuthenticationDefaultKey) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ integer: Int, forKey key: AuthenticationDefaultKey) {
        UserDefaults.standard.set(integer, forKey: key.rawValue);//namespace(key))
    }
    
    static func integer(forKey key: AuthenticationDefaultKey) -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ bool: Bool, forKey key: AuthenticationDefaultKey) {
        UserDefaults.standard.set(bool, forKey: key.rawValue);//namespace(key))
    }
    
    static func bool(forKey key: AuthenticationDefaultKey) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue);//namespace(key))
    }
}

