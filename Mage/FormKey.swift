//
//  Form.swift
//  MAGE
//
//  Created by Daniel Barela on 5/25/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum FormKey : String {
    
    case name
    case primaryField
    case secondaryField = "variantField"
    case primaryFeedField
    case secondaryFeedField
    case color
    case description
    case fields
    case userFields
    case archived
    case id

    var key: String {
        return self.rawValue
    }
}
