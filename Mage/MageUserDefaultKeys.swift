//
//  MageUserDefaultKeys.swift
//  MAGE
//
//  Created by Daniel Barela on 9/29/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc extension UserDefaults {
    
    @objc func color(forKey key: String) -> UIColor? {
        var color: UIColor?
        if let colorData = data(forKey: key) {
            do {
                try color = NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
            } catch {}
        }
        return color
    }
    
    @objc func set(_ value: UIColor?, forKey key: String) {
        var colorData: Data?
        if let color = value {
            do {
                try colorData = NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            } catch {}
        }
        set(colorData, forKey: key)
    }
    
    var showHeadingSet: Bool {
        get {
            return value(forKey: #keyPath(UserDefaults.showHeading)) != nil;
        }
    }
    
    var showHeading: Bool {
        get {
            return bool(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var bearingTargetColor: UIColor {
        get {
            return color(forKey: #function) ?? .systemGreen
        }
        set {
            set(newValue, forKey: #function)
        }
    }
    
    var headingColor: UIColor {
        get {
            return color(forKey: #function) ?? .systemRed
        }
        set {
            set(newValue, forKey: #function)
        }
    }
    
    var mapType: Int {
        get {
            return integer(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
    
    var serverMajorVersion: Int {
        get {
            return integer(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
    
    var serverMinorVersion: Int {
        get {
            return integer(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
    
    var theme: Int {
        get {
            return integer(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
    
    var currentUserId: String? {
        get {
            return string(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var loginType: String? {
        get {
            return string(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var baseServerUrl: String? {
        get {
            return string(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var showMGRS: Bool {
        get {
            return bool(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var deviceRegistered: Bool {
        get {
            return bool(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var imageUploadSizes: [String: Any]? {
        get {
            return dictionary(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var videoUploadQualities: [String: Any]? {
        get {
            return dictionary(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var loginParameters: [String: Any]? {
        get {
            return dictionary(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var authenticationStrategies: [String: Any]? {
        get {
            return dictionary(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var serverAuthenticationStrategies: [String: Any]? {
        get {
            return dictionary(forKey: #function);
        }
        set {
            set(newValue, forKey: #function);
        }
    }
    
    var observationTimeFilter: TimeFilterType {
        get {
            return TimeFilterType.init(rawValue: UInt(integer(forKey: "timeFilterKey"))) ?? TimeFilterType.all;
        }
        set {
            set(newValue.rawValue, forKey: "timeFilterKey");
        }
    }
}
