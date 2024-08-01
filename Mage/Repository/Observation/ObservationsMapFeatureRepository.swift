//
//  ObservationsMapFeatureRepository.swift
//  MAGE
//  This class provides annotations to the main map above a certain zoom level
//
//  Created by Dan Barela on 5/21/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition
import MapFramework

private struct ObservationsMapFeatureRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationsMapFeatureRepository = ObservationsMapFeatureRepository()
}

extension InjectedValues {
    var observationsMapFeatureRepository: ObservationsMapFeatureRepository {
        get { Self[ObservationsMapFeatureRepositoryProviderKey.self] }
        set { Self[ObservationsMapFeatureRepositoryProviderKey.self] = newValue }
    }
}

class ObservationsMapFeatureRepository: MapFeatureRepository, ObservableObject {
    @Injected(\.observationLocationLocalDataSource)
    var localDataSource: ObservationLocationLocalDataSource

    var dataSource: any DataSourceDefinition = DataSources.observation

    var alwaysShow: Bool = true

    var minimumZoom: Int = 7
    func getAnnotationsAndOverlays(zoom: Int, region: MKCoordinateRegion?) async -> AnnotationsAndOverlays {
        if zoom < minimumZoom {
            return AnnotationsAndOverlays(annotations: [], overlays: [])
        }
        let corners = region?.corners()
        let mapItems = await localDataSource.getMapItems(
            minLatitude: corners?.southWest.latitude,
            maxLatitude: corners?.northEast.latitude,
            minLongitude: corners?.southWest.longitude,
            maxLongitude: corners?.northEast.longitude
        )
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
