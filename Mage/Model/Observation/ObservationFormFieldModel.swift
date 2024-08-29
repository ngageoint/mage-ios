//
//  ObservationFormFieldModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct ObservationFormFieldModel: Identifiable {
    var id: Int {
        (field[FieldKey.id.key] as? Int) ?? -1
    }
    
    var field: [String: AnyHashable]
    
    var type: String {
        field[FieldKey.type.key] as? String ?? ""
    }
    
    var name: String {
        field[FieldKey.name.key] as? String ?? ""
    }
    
    var title: String {
        field[FieldKey.title.key] as? String ?? ""
    }
}
