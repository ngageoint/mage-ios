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
    
    @objc func mkcoordinateregion(forKey key: String) -> MKCoordinateRegion {
        if let regionData = array(forKey: key) as? [Double] {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: regionData[0], longitude: regionData[1]), latitudinalMeters: regionData[2], longitudinalMeters: regionData[3]);
        }
        return MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: -1, longitudeDelta: -1));
    }
    
    func setRegion(_ value: MKCoordinateRegion, forKey key: String) {
        let span = value.span
        let center = value.center
        
        let loc1 = CLLocation(latitude: center.latitude - span.latitudeDelta * 0.5, longitude: center.longitude)
        let loc2 = CLLocation(latitude: center.latitude + span.latitudeDelta * 0.5, longitude: center.longitude)
        let loc3 = CLLocation(latitude: center.latitude, longitude: center.longitude - span.longitudeDelta * 0.5)
        let loc4 = CLLocation(latitude: center.latitude, longitude: center.longitude + span.longitudeDelta * 0.5)
        
        let metersInLatitude = loc1.distance(from: loc2)
        let metersInLongitude = loc3.distance(from: loc4)
        
        let regionData: [Double] = [value.center.latitude, value.center.longitude, metersInLatitude, metersInLongitude];
        setValue(regionData, forKey: key);
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
    
    var mapRegion: MKCoordinateRegion {
        get {
            return mkcoordinateregion(forKey: #function)
        }
        set {
            setRegion(newValue, forKey: #function)
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
