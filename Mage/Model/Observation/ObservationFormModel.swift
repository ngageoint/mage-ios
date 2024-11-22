//
//  ObservationFormModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct ObservationFormModel: Identifiable {
    var id: String {
        (form[FormKey.id.key] as? String) ?? ""
    }
    
    var observationId: URL?
    
    var eventFormId: Int? {
        form[EventKey.formId.key] as? Int
    }
    
    var form: [String: AnyHashable]
}
