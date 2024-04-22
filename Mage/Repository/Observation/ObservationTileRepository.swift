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

enum DataSources {
    static let observation: ObservationDefinition = ObservationDefinition.definition
}

class ObservationDefinition: DataSourceDefinition {
    var mappable: Bool = true

    var color: UIColor = .magenta

    var imageName: String?
    
    var systemImageName: String? = "face.smiling"

    var key: String = "observations"

    var name: String = "Observations"

    var fullName: String = "Observations"

    static let definition = ObservationDefinition()
    private init() { }
}

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
        if let observationId = observationMapItem.observationId {
            return [observationId.absoluteString]
        }
        return []
    }
}

class ObservationTileRepository: TileRepository, ObservableObject {
    var dataSource: any DataSourceDefinition = DataSources.observation

    var cacheSourceKey: String?
    
    var imageCache: Kingfisher.ImageCache?
    
    var filterCacheKey: String {
        dataSource.key
    }

    var alwaysShow: Bool = true

    var observationUrl: URL?
    let localDataSource: ObservationLocationLocalDataSource

    init(observationUrl: URL?, localDataSource: ObservationLocationLocalDataSource) {
        self.observationUrl = observationUrl
        self.localDataSource = localDataSource
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
        if let observationUrl = observationUrl {
            return [observationUrl.absoluteString]
        }
        return []
    }
}

class ObservationsTileRepository: TileRepository, ObservableObject {
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

    let localDataSource: ObservationLocationLocalDataSource
    let iconRepository: ObservationIconRepository

    init(localDataSource: ObservationLocationLocalDataSource, observationIconRepository: ObservationIconRepository) {
        self.localDataSource = localDataSource
        self.iconRepository = observationIconRepository
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
        precise: Bool
    ) async -> [String] {
        await getObservationMapItems(
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude,
            latitudePerPixel: latitudePerPixel,
            longitudePerPixel: longitudePerPixel,
            zoom: zoom,
            precise: precise
        ).compactMap { item in
            item.observationId?.absoluteString
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
        precise: Bool
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

        if precise {
            var matchedItems: [ObservationMapItem] = []

            for item in items {
                guard let observationId = item.observationId else {
                    continue
                }
                let observationTileRepo = ObservationTileRepository(observationUrl: observationId, localDataSource: localDataSource)
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

            return matchedItems
        } else {
            return items
        }
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

class ObservationMapImage: DataSourceImage {
    static let annotationScaleWidth = 35.0

    var feature: SFGeometry?
    var mapItem: ObservationMapItem

    static var dataSource: any DataSourceDefinition = DataSources.observation

    init(mapItem: ObservationMapItem) {
        self.mapItem = mapItem
        feature = mapItem.geometry
    }

    func image(
        context: CGContext?,
        zoom: Int,
        tileBounds: MapBoundingBox,
        tileSize: Double
    ) -> [UIImage] {
        let coordinate: CLLocationCoordinate2D = {
            if let point = SFGeometryUtils.centroid(of: feature) {
                return CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
            }
            return kCLLocationCoordinate2DInvalid
        }()

        var iconImage: UIImage?

        if let iconPath = mapItem.iconPath {
            if let image = UIImage(contentsOfFile: iconPath) {
                let widthScale = max(0.3, (CGFloat(zoom) / 18.0)) * 35 * UIScreen.main.scale
                let scaledImage = image.aspectResize(to: CGSize(width: widthScale, height: image.size.height / (image.size.width / widthScale)))
                scaledImage.accessibilityIdentifier = iconPath
                iconImage = scaledImage
            }
        }
        
        if let iconImage = iconImage ?? UIImage(named: "defaultMarker") {
            if context != nil, CLLocationCoordinate2DIsValid(coordinate) {
                let pixel = coordinate.toPixel(
                    zoomLevel: zoom,
                    swCorner: tileBounds.swCorner,
                    neCorner: tileBounds.neCorner,
                    tileSize: tileSize)
                iconImage.draw(at: CGPoint(x: pixel.x - (iconImage.size.width / 2.0), y: pixel.y - iconImage.size.height))
            }

            return [iconImage]
        }

        return []
    }

    func polygonImage(
        polygon: MKPolygon,
        zoomLevel: Int,
        tileSize: Double,
        tileBounds3857: MapBoundingBox
    ) {
        let path = UIBezierPath()
        var first = true

        for point in UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount) {

            let pixel = point.coordinate.toPixel(
                zoomLevel: zoomLevel,
                swCorner: tileBounds3857.swCorner,
                neCorner: tileBounds3857.neCorner,
                tileSize: tileSize,
                canCross180thMeridian: polygon.boundingMapRect.spans180thMeridian)
            if first {
                path.move(to: pixel)
                first = false
            } else {
                path.addLine(to: pixel)
            }

        }

        path.lineWidth = 4
        path.close()
        DataSources.observation.color.withAlphaComponent(0.3).setFill()
        DataSources.observation.color.setStroke()
        path.fill()
        path.stroke()
    }

    func polylineImage(
        lineShape: MKPolyline,
        zoomLevel: Int,
        tileSize: Double,
        tileBounds3857: MapBoundingBox
    ) {
        let path = UIBezierPath()
        var first = true
        let points = lineShape.points()

        for point in UnsafeBufferPointer(start: points, count: lineShape.pointCount) {

            let pixel = point.coordinate.toPixel(
                zoomLevel: zoomLevel,
                swCorner: tileBounds3857.swCorner,
                neCorner: tileBounds3857.neCorner,
                tileSize: tileSize)
            if first {
                path.move(to: pixel)
                first = false
            } else {
                path.addLine(to: pixel)
            }

        }

        path.lineWidth = 4
        DataSources.observation.color.setStroke()
        path.stroke()
    }
}
