//
//  FormModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct FormModel {
    var archived: Bool
    var eventId: Int?
    var formId: Int?
    var order: Int?
    var primaryFeedField: [AnyHashable : Any]?
    var secondaryFeedField: [AnyHashable : Any]?
    var primaryMapField: [AnyHashable : Any]?
    var secondaryMapField: [AnyHashable : Any]?
    var formJson: [AnyHashable : Any]?
    
    public var name: String? {
        get {
            return formJson?[FormKey.name.key] as? String
        }
    }
    
    public var formDescription: String? {
        get {
            return formJson?[FormKey.description.key] as? String
        }
    }
    
    public var fields: [[String: AnyHashable]]? {
        get {
            return formJson?[FormKey.fields.key] as? [[String: AnyHashable]]
        }
    }
    
    public var min: Int? {
        get {
            return formJson?[FormKey.min.key] as? Int
        }
    }
    
    public var max: Int? {
        get {
            return formJson?[FormKey.max.key] as? Int
        }
    }
    
    public var isDefault: Bool {
        get {
            return formJson?[FormKey.isDefault.key] as? Bool ?? false
        }
    }
    
    public var color: String? {
        get {
            return formJson?[FormKey.color.key] as? String
        }
    }
    
    public var style: [AnyHashable:Any]? {
        get {
            return formJson?[FormKey.style.key] as? [AnyHashable:Any]
        }
    }
}

extension FormModel {
    init(form: Form) {
        archived = form.archived
        if let formEventId = form.eventId {
            eventId = Int(truncating: formEventId)
        }
        if let formFormId = form.formId {
            formId = Int(truncating: formFormId)
        }
        primaryFeedField = form.primaryFeedField
        secondaryFeedField = form.secondaryFeedField
        primaryMapField = form.primaryMapField
        secondaryMapField = form.secondaryMapField
        formJson = form.json?.json
    }
}
