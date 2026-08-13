//
//  Settings.swift
//  MAGE
//
//  Created by William Newman on 1/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Persistence

enum MapSearchType: Int32 {
    case none
    case native
    case nominatim
}

extension Settings {
    
    var mapSearchType: MapSearchType {
        get { return MapSearchType(rawValue: self.mapSearchTypeCode) ?? .none }
        set { self.mapSearchTypeCode = newValue.rawValue }
    }
    
}
