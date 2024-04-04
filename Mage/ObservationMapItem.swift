//
//  ObservationMapItem.swift
//  MAGE
//
//  Created by Daniel Barela on 3/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import sf_ios

struct ObservationMapItem {
    var observationId: URL?
    var geometry: SFGeometry?
    var iconPath: String?
    var formId: Int64?
    var fieldName: String?
    var eventId: Int64?
}

extension ObservationMapItem {
    init(observation: ObservationLocation) {
        self.observationId = observation.observation?.objectID.uriRepresentation()
        self.formId = observation.formId
        self.fieldName = observation.fieldName
        self.eventId = observation.eventId
        self.geometry = observation.geometry

        var primaryFieldText: String?
        var secondaryFieldText: String?

        if let primaryField =  observation.form?.primaryMapField,
           let observationForms = observation.observation?.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]],
           let primaryFieldName = primaryField[FieldKey.name.key] as? String,
           observationForms.count > 0
        {
            for (index, form) in observationForms.enumerated() {
                if let formId = form[FormKey.formId.key] as? Int {
                    if formId == observation.formId {
                        let primaryValue = form[primaryFieldName]
                        primaryFieldText = Observation.fieldValueText(value: primaryValue, field: primaryField)
                        if let secondaryField = observation.form?.secondaryMapField,
                           let secondaryFieldName = secondaryField[FieldKey.name.key] as? String
                        {
                            let secondaryValue = form[secondaryFieldName]
                            secondaryFieldText = Observation.fieldValueText(value: secondaryValue, field: secondaryField)
                        }
                    }
                }
            }
        }

        self.iconPath = ObservationImage.imageName(
            eventId: eventId,
            formId: formId,
            primaryFieldText: primaryFieldText,
            secondaryFieldText: secondaryFieldText
        )
    }
}
