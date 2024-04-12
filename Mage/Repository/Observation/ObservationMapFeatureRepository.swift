//
//  ObservationMapFeatureRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 4/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition

class ObservationMapFeatureRepository: MapFeatureRepository, ObservableObject {
    var dataSource: any DataSourceDefinition = DataSources.observation

    var alwaysShow: Bool = true

    let observationUri: URL
    let repository: ObservationRepository
    init(observationUri: URL, repository: ObservationRepository) {
        self.observationUri = observationUri
        self.repository = repository
    }

    func getAnnotationsAndOverlays() async -> AnnotationsAndOverlays {
        let mapItems = await repository.getMapItems(observationUri: observationUri)
        let annotations = mapItems.map { item in
            ObservationMapItemAnnotation(mapItem: item)
        }
        let overlays = mapItems.compactMap { item in
            if let accuracy = item.accuracy, 
                let geometry = item.geometry,
                let centroid = geometry.centroid()
            {
                return ObservationAccuracy(
                    center: CLLocationCoordinate2D(
                        latitude: centroid.y.doubleValue,
                        longitude: centroid.x.doubleValue
                    ),
                    radius: accuracy
                )
            }
            return nil
        }
        return AnnotationsAndOverlays(annotations: annotations, overlays: overlays)
    }

    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]? {
        return []
    }
}

class ObservationMapItemAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var mapItem: ObservationMapItem
    var title: String?
    var subtitle: String?

    init(mapItem: ObservationMapItem) {
        self.mapItem = mapItem
        if let point = mapItem.geometry?.centroid() {
            self.coordinate = CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
        } else {
            self.coordinate = kCLLocationCoordinate2DInvalid
        }
    }
}
