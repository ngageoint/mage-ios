//
//  ObservationsTileRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceTileOverlay
import DataSourceDefinition
import Kingfisher
import Combine

private struct ObservationsTileRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationsTileRepository = ObservationsTileRepository()
}

extension InjectedValues {
    var observationsTileRepository: ObservationsTileRepository {
        get { Self[ObservationsTileRepositoryProviderKey.self] }
        set { Self[ObservationsTileRepositoryProviderKey.self] = newValue }
    }
}

class ObservationsTileRepository: TileRepository, ObservableObject {
    @Injected(\.observationLocationLocalDataSource)
    var localDataSource: ObservationLocationLocalDataSource
    
    @Injected(\.observationIconRepository)
    var iconRepository: ObservationIconRepository

    var cancellable = Set<AnyCancellable>()

    var refreshPublisher: AnyPublisher<Date, Never>? {
        refreshSubject?.eraseToAnyPublisher()
    }

    var refreshSubject: PassthroughSubject<Date, Never>? = PassthroughSubject<Date, Never>()

    var alwaysShow: Bool = true
    var dataSource: any DataSourceDefinition = DataSources.observation
    var cacheSourceKey: String? = nil // { dataSource.key }
    var imageCache: Kingfisher.ImageCache? = nil
//    {
//        if let cacheSourceKey = cacheSourceKey {
//            return Kingfisher.ImageCache(name: cacheSourceKey)
//        }
//        return nil
//    }
    var filterCacheKey: String {
        dataSource.key
//        UserDefaults.standard.filter(DataSources.asam).getCacheKey()
    }

    var eventIdToMaxIconSize: [Int: CGSize?] = [:]

    init() {
        _ = getMaximumIconHeightToWidthRatio()

        self.localDataSource.publisher()
            .dropFirst()
            .sink { changes in
                Task {
                    var regions: [MKCoordinateRegion] = []
                    for change in changes {
                        switch (change) {
                        case .insert(offset: let offset, element: let element, associatedWith: let associatedWith):
                            if let region = element.region {
                                regions.append(region)
                            }
                        case .remove(offset: let offset, element: let element, associatedWith: let associatedWith):
                            if let region = element.region {
                                regions.append(region)
                            }
                        }
                    }

                    await self.clearCache(regions: regions)
                    self.refreshSubject?.send(Date())
                }
            }
            .store(in: &cancellable)

        NotificationCenter.default.publisher(for: .MAGEFormFetched)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                if let event: Event = notification.object as? Event {
                    if event.remoteId == Server.currentEventId() {
                        Task {
                            if let eventId = event.remoteId {
                                self.eventIdToMaxIconSize[eventId.intValue] = nil
                            }
                            await self.clearCache()
                            self.refreshSubject?.send(Date())
                        }
                    }
                }
            }
            .store(in: &cancellable)
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
    ) async -> [DataSourceImage] {
        await getObservationMapItems(
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude,
            latitudePerPixel: latitudePerPixel,
            longitudePerPixel: longitudePerPixel,
            zoom: zoom,
            precise: precise
        ).map { item in
            ObservationMapImage(mapItem: item)
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
        precise: Bool,
        distanceTolerance: Double
    ) async -> [String] {
        await getObservationMapItems(
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude,
            latitudePerPixel: latitudePerPixel,
            longitudePerPixel: longitudePerPixel,
            zoom: zoom,
            precise: precise,
            distanceTolerance: distanceTolerance
        ).compactMap { item in
            item.observationLocationId?.absoluteString
        }
    }

    private func getObservationMapItems(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double,
        latitudePerPixel: Double,
        longitudePerPixel: Double,
        zoom: Int,
        precise: Bool,
        distanceTolerance: Double = 0
    ) async -> [ObservationMapItem] {

        // determine widest and tallest icon at this zoom level pixels
        let iconPixelSize = getMaxHeightAndWidth(zoom: zoom)

        // this is how many degrees to add and subtract to ensure we query for the item around the tap location
        let iconToleranceHeightDegrees = latitudePerPixel * iconPixelSize.height
        let iconToleranceWidthDegrees = longitudePerPixel * iconPixelSize.width

        let queryLocationMinLongitude = minLongitude - iconToleranceWidthDegrees
        let queryLocationMaxLongitude = maxLongitude + iconToleranceWidthDegrees
        let queryLocationMinLatitude = minLatitude - iconToleranceHeightDegrees
        let queryLocationMaxLatitude = maxLatitude + iconToleranceHeightDegrees

        let items = await localDataSource.getMapItems(
            minLatitude: queryLocationMinLatitude,
            maxLatitude: queryLocationMaxLatitude,
            minLongitude: queryLocationMinLongitude,
            maxLongitude: queryLocationMaxLongitude)

        var matchedItems: [ObservationMapItem] = []
        
        let tapLocation = CLLocationCoordinate2DMake(maxLatitude - ((maxLatitude - minLatitude) / 2.0), maxLongitude - ((maxLongitude - minLongitude) / 2.0))

        for item in items {
            guard let observationLocationId = item.observationLocationId else {
                continue
            }
            if !precise {
                matchedItems.append(item)
                continue
            }
            
            let observationTileRepo = ObservationLocationTileRepository(observationLocationUrl: observationLocationId)
            let tileProvider = DataSourceTileOverlay(tileRepository: observationTileRepo, key: DataSources.observation.key)
            if item.geometry is SFPoint {
                matchedItems.append(item)
//                let include = await markerHitTest(
//                    location: tapLocation,
//                    zoom: zoom,
//                    tileProvider: tileProvider
//                )
//                if include {
//                    matchedItems.append(item)
//                }
            } else {
                let mkshape = MKShape.fromGeometry(geometry: item.geometry, distance: nil)
                if let polygon = mkshape as? MKPolygon {
                    let include = polygon.hitTest(
                        location: tapLocation
                    )
                    if include {
                        matchedItems.append(item)
                    }
                } else if let line = mkshape as? MKPolyline {
                    let include = line.hitTest(location: tapLocation, distanceTolerance: distanceTolerance)
                    if include {
                        matchedItems.append(item)
                    }
                }
            }
        }

        return matchedItems
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
