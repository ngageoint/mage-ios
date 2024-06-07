//
//  ObservationTileRepository.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceTileOverlay
import Kingfisher
import DataSourceDefinition
import Combine

class ObservationTileRepository: TileRepository, ObservableObject {
    @Injected(\.observationLocationLocalDataSource)
    var localDataSource: ObservationLocationLocalDataSource

    var dataSource: any DataSourceDefinition = DataSources.observation

    var cacheSourceKey: String?
    
    var imageCache: Kingfisher.ImageCache?
    
    var filterCacheKey: String {
        dataSource.key
    }

    var alwaysShow: Bool = true

    var observationUrl: URL?

    init(observationUrl: URL?) {
        self.observationUrl = observationUrl
    }

    func getTileableItems(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double,
        latitudePerPixel: Double,
        longitudePerPixel: Double,
        zoom: Int,
        precise: Bool
    ) async -> [any DataSourceImage] {
        return await localDataSource.getMapItems(
            observationUri: observationUrl,
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude
        )
        .map({ mapItem in
            ObservationMapImage(mapItem: mapItem)
        })
    }
    
    func getItemKeys(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double,
        latitudePerPixel: Double,
        longitudePerPixel: Double,
        zoom: Int,
        precise: Bool
    ) async -> [String] {
        return await localDataSource.getMapItems(
            observationUri: observationUrl,
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude
        )
        .compactMap({ mapItem in
            mapItem.observationLocationId?.absoluteString
        })
    }
}
