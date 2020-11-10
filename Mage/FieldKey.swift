//
//  FieldKey.swift
//  MAGE
//
//  Created by Daniel Barela on 5/25/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum FieldKey : String {
    
    case title
    case type
    case required
    case id
    case name
    case choices
    case value
    case min
    case max
    case archived
    case hidden
    
    var key: String {
        return self.rawValue
    }
}
