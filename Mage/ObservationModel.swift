//
//  ObservationModel.swift
//  MAGE
//
//  Created by Dan Barela on 7/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct ObservationModel: Equatable, Hashable {
    static func == (lhs: ObservationModel, rhs: ObservationModel) -> Bool {
        lhs.observationId == rhs.observationId && lhs.lastModified == rhs.lastModified
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(observationId)
        hasher.combine(lastModified)
    }
    
    var observationId: URL?
    var geometry: SFGeometry?
    var formId: Int?
    var eventId: Int?
    var accuracy: Double?
    var provider: String?
    var timestamp: Date?
    var userId: URL?
    var error: Bool = false
    var syncing: Bool = false
    var isDirty: Bool = false
    var errorMessage: String?
    var lastModified: Date?
    var important: ObservationImportantModel?
    var properties: [AnyHashable: AnyObject]?

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
}

extension ObservationModel {
    init(observation: Observation) {
        self.observationId = observation.objectID.uriRepresentation()
        self.geometry = observation.geometry
        if let eventId = observation.eventId {
            self.eventId = Int(truncating: eventId)
        }
        self.geometry = observation.geometry
        self.accuracy = observation.getAccuracy()
        self.provider = observation.getProvider()
        
        if let primaryObservationForm = observation.primaryObservationForm {
            self.formId = primaryObservationForm[EventKey.formId.key] as? Int
        }
        self.error = observation.error != nil && observation.hasValidationError
        self.errorMessage = observation.errorMessage
        self.syncing = observation.error != nil && !observation.hasValidationError
        self.isDirty = observation.isDirty
        self.lastModified = observation.lastModified
        self.timestamp = observation.timestamp
        self.properties = observation.properties as? [AnyHashable : AnyObject]
        if let observationImportant = observation.observationImportant {
            self.important = ObservationImportantModel(observationImportant: observationImportant)
        }
        self.userId = observation.user?.objectID.uriRepresentation()
    }
}
