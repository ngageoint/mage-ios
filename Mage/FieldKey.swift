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
    case remoteId
    
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
    case accuracy
    case provider
    case delta
    case timestamp
    case geometry
    case important
    case lastModified
    case remoteId
    case favoriteUserIds
    case attachments
    case userId
    case deviceId
    case url
    case id
    case properties
    
    var key: String {
        return self.rawValue
    }
}

public enum AttachmentKey : String {
    case contentType
    case name
    case remotePath
    case size
    case url
    case id
    
    var key: String {
        return self.rawValue
    }
}


public enum UserKey : String {
    case remoteId
    
    var key: String {
        return self.rawValue
    }
}

public enum PermissionsKey: String {
    case permissions
    
    case update
    case DELETE_OBSERVATION
    case UPDATE_EVENT
    
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
    case hidden
    
    var key: String {
        return self.rawValue
    }
}

