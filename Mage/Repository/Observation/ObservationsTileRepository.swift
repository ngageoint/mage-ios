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
        self.localDataSource.locationsPublisher()
            .dropFirst()
            .sink { changes in
                Task {
                    var regions: [MKCoordinateRegion] = []
                    for change in changes {
                        switch (change) {
                        case .insert(offset: _, element: let element, associatedWith: _):
                            if let region = element.region {
                                regions.append(region)
                            }
                        case .remove(offset: _, element: let element, associatedWith: _):
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
                if let event: EventModel = notification.object as? EventModel {
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
        let iconPixelSize = await getMaxHeightAndWidth(zoom: zoom)

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
            

            if item.geometry is SFPoint {
                // if we matched more than 50 things, just return them, they need to zoom in more
                if items.count > 50 {
                    matchedItems.append(item)
                } else {
                    let observationTileRepo = ObservationLocationTileRepository(observationLocationUrl: observationLocationId)
                    let tileProvider = DataSourceTileOverlay(tileRepository: observationTileRepo, key: DataSources.observation.key)
                    let include = await markerHitTest(
                        location: tapLocation,
                        zoom: zoom,
                        tileProvider: tileProvider
                    )
                    if include {
                        matchedItems.append(item)
                    }
                }
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

    func getMaximumIconHeightToWidthRatio() async -> CGSize {
        if let currentEvent = Server.currentEventId() {
            return await iconRepository.getMaximumIconHeightToWidthRatio(eventId: currentEvent.intValue)
        }
        return .zero
    }

    func getMaxHeightAndWidth(zoom: Int) async -> CGSize {
        // icons should be a max of 35 wide
        let pixelWidthTolerance = max(0.3, (CGFloat(zoom) / 18.0)) * 35
        // if the icon is pixelWidthTolerance wide, the max height is this
        let maxRatio = await getMaximumIconHeightToWidthRatio()
        let pixelHeightTolerance = (pixelWidthTolerance / maxRatio.width) * maxRatio.height
        return await CGSize(width: pixelWidthTolerance * UIScreen.main.scale, height: pixelHeightTolerance * UIScreen.main.scale)
    }
}
