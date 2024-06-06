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
        let annotations = mapItems.map { item in
            ObservationMapItemAnnotation(mapItem: item)
        }
        return AnnotationsAndOverlays(annotations: annotations, overlays: [])
    }

    func items(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [Any]? {
        return []
    }
}
