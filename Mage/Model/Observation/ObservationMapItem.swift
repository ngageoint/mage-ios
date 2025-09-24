//
//  ObservationMapItem.swift
//  MAGE
//
//  Created by Daniel Barela on 3/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SimpleFeatures

struct ObservationMapItem: Equatable, Hashable {
    var observationId: URL?
    var observationLocationId: URL?
    var geometry: SFGeometry?
    var formId: Int?
    var fieldName: String?
    var eventId: Int64?
    var accuracy: Double?
    var provider: String?
    var maxLatitude: Double?
    var maxLongitude: Double?
    var minLatitude: Double?
    var minLongitude: Double?
    var primaryFieldText: String?
    var secondaryFieldText: String?
    var strokeColor: UIColor?
    var fillColor: UIColor?
    var lineWidth: CGFloat?
    var timestamp: Date?
    var user: String?
    var error: Bool = false
    var syncing: Bool = false
    var important: ObservationImportantModel?
    var iconPath: String?

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
        let center = CLLocationCoordinate2D(
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
    init(observation: ObservationLocation, imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl.shared) {
        self.observationId = observation.observation?.objectID.uriRepresentation()
        self.observationLocationId = observation.objectID.uriRepresentation()
        self.formId = Int(observation.formId)
        self.fieldName = observation.fieldName
        self.eventId = observation.eventId
        self.geometry = observation.geometry
        self.accuracy = observation.accuracy
        self.provider = observation.provider
        self.maxLatitude = observation.maxLatitude
        self.maxLongitude = observation.maxLongitude
        self.minLatitude = observation.minLatitude
        self.minLongitude = observation.minLongitude
        self.primaryFieldText = observation.primaryFieldText
        self.secondaryFieldText = observation.secondaryFieldText
        self.iconPath = imageRepository.imageName(
            eventId: eventId,
            formId: formId,
            primaryFieldText: primaryFieldText,
            secondaryFieldText: secondaryFieldText
        )
        // TODO: should we store the primary and secondary feed field text too?
        if let observation = observation.observation {
            let style = ObservationShapeStyleParser.style(
                observation: observation,
                primaryFieldText: primaryFieldText,
                secondaryFieldText: secondaryFieldText
            )
            self.strokeColor = style.strokeColor
            self.fillColor = style.fillColor
            self.lineWidth = style.lineWidth
            self.timestamp = observation.timestamp
            self.user = observation.user?.name
            self.error = observation.error != nil && observation.hasValidationError
            self.syncing = observation.error != nil && !observation.hasValidationError
            if let observationImportant = observation.observationImportant {
                self.important = ObservationImportantModel(observationImportant: observationImportant)
            }
        }
    }
}
