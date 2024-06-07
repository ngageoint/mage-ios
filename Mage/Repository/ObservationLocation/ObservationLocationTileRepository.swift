//
//  ObservationLocationTileRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceTileOverlay
import DataSourceDefinition
import Kingfisher

class ObservationLocationTileRepository: TileRepository, ObservableObject {
    @Injected(\.observationLocationLocalDataSource)
    var localDataSource: ObservationLocationLocalDataSource
    
    @Injected(\.observationIconRepository)
    var iconRepository: ObservationIconRepository

    var dataSource: any DataSourceDefinition = DataSources.observation

    var cacheSourceKey: String?
    
    var imageCache: Kingfisher.ImageCache?
    
    var filterCacheKey: String {
        dataSource.key
    }

    var alwaysShow: Bool = true

    var observationLocationUrl: URL?
    var observationUrl: URL?
    
    var eventIdToMaxIconSize: [Int: CGSize?] = [:]
    
    init(observationLocationUrl: URL?) {
        self.observationLocationUrl = observationLocationUrl
        _ = getMaximumIconHeightToWidthRatio()
    }
    
    init(observationUrl: URL?) {
        self.observationUrl = observationUrl
        _ = getMaximumIconHeightToWidthRatio()
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
        var items: [ObservationMapItem]?
        
        let iconPixelSize = getMaxHeightAndWidth(zoom: zoom)

        // this is how many degrees to add and subtract to ensure we query for the item around the tap location
        let iconToleranceHeightDegrees = latitudePerPixel * iconPixelSize.height
        let iconToleranceWidthDegrees = longitudePerPixel * iconPixelSize.width

        let queryLocationMinLongitude = minLongitude - iconToleranceWidthDegrees
        let queryLocationMaxLongitude = maxLongitude + iconToleranceWidthDegrees
        let queryLocationMinLatitude = minLatitude - iconToleranceHeightDegrees
        let queryLocationMaxLatitude = maxLatitude + iconToleranceHeightDegrees
        
        if let observationLocationUrl = observationLocationUrl {
            items = await localDataSource.getMapItems(
                observationLocationUri: observationLocationUrl,
                minLatitude: queryLocationMinLatitude,
                maxLatitude: queryLocationMaxLatitude,
                minLongitude: queryLocationMinLongitude,
                maxLongitude: queryLocationMaxLongitude
            )
//            .map({ mapItem in
//                ObservationMapImage(mapItem: mapItem)
//            })
        } else if let observationUrl = observationUrl {
            items = await localDataSource.getMapItems(
                observationUri: observationUrl,
                minLatitude: queryLocationMinLatitude,
                maxLatitude: queryLocationMaxLatitude,
                minLongitude: queryLocationMinLongitude,
                maxLongitude: queryLocationMaxLongitude
            )
//            .map({ mapItem in
//                ObservationMapImage(mapItem: mapItem)
//            })
        }
        
        guard let items = items else {
            return []
        }
        if precise {
            var matchedItems: [ObservationMapItem] = []

            for item in items {
                guard let observationId = item.observationId else {
                    continue
                }
                let observationTileRepo = ObservationTileRepository(observationUrl: observationId)
                let tileProvider = DataSourceTileOverlay(tileRepository: observationTileRepo, key: DataSources.observation.key)
                if item.geometry is SFPoint {
                    let include = await markerHitTest(
                        location: CLLocationCoordinate2DMake(maxLatitude - ((maxLatitude - minLatitude) / 2.0), maxLongitude - ((maxLongitude - minLongitude) / 2.0)),
                        zoom: zoom,
                        tileProvider: tileProvider
                    )
                    if include {
                        matchedItems.append(item)
                    }
                }
            }

            return matchedItems.map({ mapItem in
                ObservationMapImage(mapItem: mapItem)
            })
        } else {
            return items.map({ mapItem in
                ObservationMapImage(mapItem: mapItem)
            })
        }
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
        if let observationLocationUrl = observationLocationUrl {
            return [observationLocationUrl.absoluteString]
        }
        return []
    }
    
    func getMaximumIconHeightToWidthRatio() -> CGSize {
        if let currentEvent = Server.currentEventId() {
            if let calculatedSize = eventIdToMaxIconSize[currentEvent.intValue] as? CGSize {
                return calculatedSize
            }
            let size = iconRepository.getMaximumIconHeightToWidthRatio(eventId: currentEvent.intValue)
            eventIdToMaxIconSize[currentEvent.intValue] = size
            return size
        }
        return .zero
    }

    func getMaxHeightAndWidth(zoom: Int) -> CGSize {
        // icons should be a max of 35 wide
        let pixelWidthTolerance = max(0.3, (CGFloat(zoom) / 18.0)) * 35
        // if the icon is pixelWidthTolerance wide, the max height is this
        let pixelHeightTolerance = (pixelWidthTolerance / getMaximumIconHeightToWidthRatio().width) * getMaximumIconHeightToWidthRatio().height
        return CGSize(width: pixelWidthTolerance * UIScreen.main.scale, height: pixelHeightTolerance * UIScreen.main.scale)
    }
}
