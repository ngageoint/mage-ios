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

struct AnnotationsAndOverlays {
    let annotations: [DataSourceAnnotation]
    let overlays: [MKOverlay]
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
