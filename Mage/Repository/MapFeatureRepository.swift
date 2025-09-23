//
//  MapFeatureRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 4/5/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import GeoPackage
import DataSourceDefinition
import MapFramework

struct AnnotationsAndOverlays: Sendable {
    let annotations: [DataSourceAnnotation] // Error: Stored property 'annotations' of 'Sendable'-conforming struct 'AnnotationsAndOverlays' has non-sendable type '[DataSourceAnnotation]'
    let overlays: [MKOverlay] // Error: Stored property 'overlays' of 'Sendable'-conforming struct 'AnnotationsAndOverlays' has non-sendable type '[any MKOverlay]'
}

protocol MapFeatureRepository {
    var dataSource: any DataSourceDefinition { get }
    var alwaysShow: Bool { get }

    func getAnnotationsAndOverlays(zoom: Int, region: MKCoordinateRegion?) async -> AnnotationsAndOverlays
    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]?
}
