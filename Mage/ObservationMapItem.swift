//
//  ObservationMapItem.swift
//  MAGE
//
//  Created by Daniel Barela on 3/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import sf_ios

struct ObservationMapItem: Equatable {
    var observationId: URL?
    var geometry: SFGeometry?
    var iconPath: String?
    var formId: Int64?
    var fieldName: String?
    var eventId: Int64?
    var accuracy: Double?
    var provider: String?
    var maxLatitude: Double?
    var maxLongitude: Double?
    var minLatitude: Double?
    var minLongitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let geometry = geometry, let point = geometry.centroid() else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
    }

    var accuracyDisplay: String? {
        if self.provider == "manual" {
            return nil
        }
        if let accuracy = accuracy, let provider = provider {
            var formattedProvider: String = ""
            if provider == "gps" {
                formattedProvider = provider.uppercased()
            } else {
                formattedProvider = provider.capitalized
            }
            return String(format: "%@ ± %.02fm", formattedProvider, accuracy)
        }
        return nil
    }

    var region: MKCoordinateRegion? {
        guard let maxLatitude = maxLatitude,
              let maxLongitude = maxLongitude,
              let minLatitude = minLatitude,
              let minLongitude = minLongitude
        else {
            return nil
        }
        var center = CLLocationCoordinate2D(
            latitude: maxLatitude - ((maxLatitude - minLatitude) / 2.0),
            longitude: maxLongitude - ((maxLongitude - minLongitude) / 2.0)
        )
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: maxLatitude - minLatitude,
                longitudeDelta: maxLongitude - minLongitude
            )
        )
    }
}

extension ObservationMapItem {
    init(observation: ObservationLocation) {
        self.observationId = observation.observation?.objectID.uriRepresentation()
        self.formId = observation.formId
        self.fieldName = observation.fieldName
        self.eventId = observation.eventId
        self.geometry = observation.geometry
        self.accuracy = observation.accuracy
        self.provider = observation.provider
        self.maxLatitude = observation.maxLatitude
        self.maxLongitude = observation.maxLongitude
        self.minLatitude = observation.minLatitude
        self.minLongitude = observation.minLongitude

        var primaryFieldText: String?
        var secondaryFieldText: String?

        let form = observation.form
        if let eventForm = form,
           let primaryField =  eventForm.primaryMapField,
           let observationForms = observation.observation?.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]],
           let primaryFieldName = primaryField[FieldKey.name.key] as? String,
           observationForms.count > 0
        {
            for form in observationForms {
                if let formId = form[FormKey.formId.key] as? Int,
                   formId == observation.formId
                {
                    let primaryValue = form[primaryFieldName]
                    primaryFieldText = Observation.fieldValueText(value: primaryValue, field: primaryField)
                    if let secondaryField = eventForm.secondaryMapField,
                       let secondaryFieldName = secondaryField[FieldKey.name.key] as? String
                    {
                        let secondaryValue = form[secondaryFieldName]
                        secondaryFieldText = Observation.fieldValueText(value: secondaryValue, field: secondaryField)
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
