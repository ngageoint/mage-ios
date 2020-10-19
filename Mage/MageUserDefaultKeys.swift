//
//  MageUserDefaultKeys.swift
//  MAGE
//
//  Created by Daniel Barela on 9/29/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    struct MageServerDefaults: MageServerDefaultable {
        private init() { }
        
        enum MageServerDefaultKey: String {
            case baseServerUrl
            case currentUserId
            case currentEventId
            case gpsDistanceFilter
            case gpsSensitivities
            case disclaimerText
            case disclaimerTitle
            case loginParameters
            case tokenExpirationLength
            case deviceRegistered
            case loginType
            case showDisclaimer
            case authenticationStrategies
            case serverAuthenticationStrategies
            case serverMajorVersion
            case serverMinorVersion
        }
    }
    
    struct Preferences: PreferencesDefaultable {
        private init() { }
        
        enum PreferencesDefaultKey: String {
            case imageUploadSizes
            case videoUploadQualities
            case showDisclaimer
            case gmtTimeZone
            case networkSyncOptions
            case attachmentFetchEnabled
            case dataFetchEnabled
            case userReportingFrequency
            case userReporting
            case reportLocation
            case wifiNetworkRestrictionType
            case wifiWhitelist
            case wifiBlacklist
            case attachmentPushFrequency
            case userFetchFrequency
            case observationFetchFrequency
            case observationPushFrequency
        }
    }
    
    struct Map: MapDefaultable {
        private init() { }
        
        enum MapDefaultKey: String {
            case map
            case selectedCaches
            case selectedStaticLayers
            case selectedOnlineLayers
            case fill_default_line_width
            case line_default_color
            case line_default_color_alpha
            case fill_default_color
            case fill_default_color_alpha
            case geopackage_feature_tiles_max_points_per_tile
            case geopackage_feature_tiles_max_features_per_tile
            case geopackage_features_max_points_per_table
            case geopackage_features_max_features_per_table
            case shape_screen_click_percentage
            case geopackage_feature_tiles_min_zoom_offset
        }
    }
    
    struct Authentication: AuthenticationDefaultable {
        private init() { }
        
        enum AuthenticationDefaultKey: String {
            case deviceRegistered
            case loginType
            case showDisclaimer
        }
    }
    
    struct Display: DisplayDefaultable {
        private init() { }
        
        enum DisplayDefaultKey: String {
            case theme
            case mapType
            case mapShowTraffic
            case showMGRS
            case hideObservations
            case hidePeople
        }
    }
    
    struct Filter: FilterDefaultable {
        private init() { }
        
        enum FilterDefaultKey: String {
            case timeFilterKey
            case timeFilterUnitKey
            case timeFilterNumberKey
            case locationtimeFilterKey
            case locationtimeFilterUnitKey
            case locationtimeFilterNumberKey
            case importantFilterKey
            case favortiesFilterKey
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

protocol DisplayDefaultable: KeyNamespaceable {
    associatedtype DisplayDefaultKey: RawRepresentable
}

extension DisplayDefaultable where DisplayDefaultKey.RawValue == String {
    
    static func set(_ string: String, forKey key: DisplayDefaultKey) {
        UserDefaults.standard.set(string, forKey: key.rawValue);//namespace(key))
    }
    
    static func string(forKey key: DisplayDefaultKey) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ integer: Int, forKey key: DisplayDefaultKey) {
        UserDefaults.standard.set(integer, forKey: key.rawValue);//namespace(key))
    }
    
    static func integer(forKey key: DisplayDefaultKey) -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue);//namespace(key))
    }
}

protocol PreferencesDefaultable: KeyNamespaceable {
    associatedtype PreferencesDefaultKey: RawRepresentable
}

extension PreferencesDefaultable where PreferencesDefaultKey.RawValue == String {
    
    static func set(_ string: String, forKey key: PreferencesDefaultKey) {
        UserDefaults.standard.set(string, forKey: key.rawValue);//namespace(key))
    }
    
    static func string(forKey key: PreferencesDefaultKey) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ integer: Int, forKey key: PreferencesDefaultKey) {
        UserDefaults.standard.set(integer, forKey: key.rawValue);//namespace(key))
    }
    
    static func integer(forKey key: PreferencesDefaultKey) -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ dictionary: Dictionary<String, Any>, forKey key: PreferencesDefaultKey) {
        UserDefaults.standard.set(dictionary, forKey: key.rawValue);//namespace(key))
    }
    
    static func dictionary(forKey key: PreferencesDefaultKey) -> [String : Any]? {
        return UserDefaults.standard.dictionary(forKey: key.rawValue);//namespace(key))
    }
}

protocol FilterDefaultable: KeyNamespaceable {
    associatedtype FilterDefaultKey: RawRepresentable
}

extension FilterDefaultable where FilterDefaultKey.RawValue == String {
    
    static func set(_ string: String, forKey key: FilterDefaultKey) {
        UserDefaults.standard.set(string, forKey: key.rawValue);//namespace(key))
    }
    
    static func string(forKey key: FilterDefaultKey) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue);//namespace(key))
    }
    
    static func set(_ integer: Int, forKey key: FilterDefaultKey) {
        UserDefaults.standard.set(integer, forKey: key.rawValue);//namespace(key))
    }
    
    static func integer(forKey key: FilterDefaultKey) -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue);//namespace(key))
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
    
    static func set(_ dictionary: Dictionary<String, Any>, forKey key: MageServerDefaultKey) {
        UserDefaults.standard.set(dictionary, forKey: key.rawValue);//namespace(key))
    }
    
    static func dictionary(forKey key: MageServerDefaultKey) -> [String : Any]? {
        return UserDefaults.standard.dictionary(forKey: key.rawValue);//namespace(key))
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

