//
//  Settings.swift
//  MAGE
//
//  Created by William Newman on 1/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum MapSearchType: Int32 {
    case none
    case native
    case nominatim
}

@objc public class Settings: NSManagedObject {
    
    var mapSearchType: MapSearchType {
        get { return MapSearchType(rawValue: self.mapSearchTypeCode) ?? .none }
        set { self.mapSearchTypeCode = newValue.rawValue }
    }
    
    @objc public func populate(_ json: [AnyHashable : Any]) {
        self.mapSearchUrl = json[SettingsKey.mobileNominatimUrl.key] as? String
        let mapSearchType = json[SettingsKey.mobileSearchType.key] as? String
        switch (mapSearchType) {
            case "NATIVE": self.mapSearchType = .native
            case "NOMINATIM": self.mapSearchType = .nominatim
            default: self.mapSearchType = .none
        }
    }
}
