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

class ObservationsTileRepository: TileRepository, ObservableObject {
    var alwaysShow: Bool = true
    var dataSource: any DataSourceDefinition = DataSources.observation
    var cacheSourceKey: String? { dataSource.key }
    var imageCache: Kingfisher.ImageCache? {
//        if let cacheSourceKey = cacheSourceKey {
//            return Kingfisher.ImageCache(name: cacheSourceKey)
//        }
        return nil
    }
    var filterCacheKey: String {
        dataSource.key
//        UserDefaults.standard.filter(DataSources.asam).getCacheKey()
    }
    let localDataSource: ObservationLocalDataSource

    init(localDataSource: ObservationLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func getTileableItems(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) async -> [DataSourceImage] {
//        if !UserDefaults.standard.showOnMapasam {
//            return []
//        }
        return await localDataSource.getObservationMapItemsInBounds(
//            filters: UserDefaults.standard.filter(DataSources.asam),
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude)
        .map { model in
            return ObservationMapImage(mapItem: model)
        }
    }

    func getItemKeys(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) async -> [String] {
        return []
//        if !UserDefaults.standard.showOnMapasam {
//            return []
//        }
//        return await localDataSource.getAsamsInBounds(
//            filters: UserDefaults.standard.filter(DataSources.asam),
//            minLatitude: minLatitude,
//            maxLatitude: maxLatitude,
//            minLongitude: minLongitude,
//            maxLongitude: maxLongitude)
//        .map { model in
//            model.itemKey
//        }
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
        tileBounds3857: MapBoundingBox
    ) {
        let path = UIBezierPath()
        var first = true

        for point in UnsafeBufferPointer(start: polygon.points(), count: polygon.pointCount) {

            let pixel = point.coordinate.toPixel(
                zoomLevel: zoomLevel,
                swCorner: tileBounds3857.swCorner,
                neCorner: tileBounds3857.neCorner,
                tileSize: TILE_SIZE,
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
                tileSize: TILE_SIZE)
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
