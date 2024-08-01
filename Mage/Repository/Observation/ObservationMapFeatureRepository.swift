//
//  ObservationMapFeatureRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 4/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition
import MapFramework

class ObservationMapFeatureRepository: MapFeatureRepository, ObservableObject {
    @Injected(\.observationMapItemRepository)
    var mapItemRepository: ObservationMapItemRepository
    
    var dataSource: any DataSourceDefinition = DataSources.observation

    var alwaysShow: Bool = true

    let observationUri: URL

    init(observationUri: URL) {
        self.observationUri = observationUri
    }

    func getAnnotationsAndOverlays(zoom: Int, region: MKCoordinateRegion? = nil) async -> AnnotationsAndOverlays {
        let mapItems = await mapItemRepository.getMapItems(observationUri: observationUri)
        let annotations = mapItems.compactMap { item in
            if item.geometry is SFPoint {
                return ObservationMapItemAnnotation(mapItem: item)
            }
            return nil
        }
        let overlays: [MKOverlay] = mapItems.compactMap { item in
            if let overlay = MKShape.fromGeometry(geometry: item.geometry, distance: nil) as? MKOverlay {
                if let polygon = overlay as? MKPolygon {
                    let styledPolygon = StyledPolygon.create(polygon: polygon)
                    styledPolygon.lineWidth = item.lineWidth ?? 1.0
                    styledPolygon.fillColor = item.fillColor
                    styledPolygon.lineColor = item.strokeColor ?? .clear
                    styledPolygon.id = item.observationLocationId?.absoluteString ?? UUID().uuidString
                    styledPolygon.itemKey = item.observationLocationId?.absoluteString ?? ""
                    styledPolygon.dataSource = DataSources.observation
                    return styledPolygon
                } else if let polyline = overlay as? MKPolyline {
                    let styledPolyline = StyledPolyline.create(polyline: polyline)
                    styledPolyline.lineWidth = item.lineWidth ?? 1.0
                    styledPolyline.lineColor = item.strokeColor ?? .clear
                    styledPolyline.id = item.observationLocationId?.absoluteString ?? UUID().uuidString
                    styledPolyline.itemKey = item.observationLocationId?.absoluteString ?? ""
                    styledPolyline.dataSource = DataSources.observation
                    return styledPolyline
                }
            }
            
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
