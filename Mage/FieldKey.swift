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
    case allowedAttachmentTypes
    
    var key: String {
        return self.rawValue
    }
}

public enum EventKey : String {
    
    case id
    case forms
    case name
    case description
    case formId
    
    var key: String {
        return self.rawValue
    }
}

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

public enum ObservationKey : String {
    
    case forms
    
    var key: String {
        return self.rawValue
    }
}

public enum FieldType : String {
    
    case attachment
    case numberfield
    case textfield
    case textarea
    case email
    case password
    case date
    case checkbox
    case dropdown
    case geometry
    case radio
    case multiselectdropdown
    
    var key: String {
        return self.rawValue
    }
}

