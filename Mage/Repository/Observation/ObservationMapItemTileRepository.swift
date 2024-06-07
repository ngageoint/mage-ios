//
//  ObservationMapItemTileRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceTileOverlay
import DataSourceDefinition
import Kingfisher

class ObservationMapItemTileRepository: TileRepository, ObservableObject {
    var dataSource: any DataSourceDefinition = DataSources.observation

    var cacheSourceKey: String?

    var imageCache: Kingfisher.ImageCache?

    var filterCacheKey: String {
        dataSource.key
    }

    var alwaysShow: Bool = true

    var observationMapItem: ObservationMapItem

    init(observationMapItem: ObservationMapItem) {
        self.observationMapItem = observationMapItem
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
        [ObservationMapImage(mapItem: observationMapItem)]
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
        if let observationLocationId = observationMapItem.observationLocationId {
            return [observationLocationId.absoluteString]
        }
        return []
    }
}
