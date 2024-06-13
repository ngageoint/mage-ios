//
//  ObservationMapImage.swift
//  MAGE
//
//  Created by Dan Barela on 6/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher
import DebugUtilities
import DataSourceDefinition
import DataSourceTileOverlay

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
        let w = WatchDog(named: "image")
        let coordinate: CLLocationCoordinate2D = {
            if let point = SFGeometryUtils.centroid(of: feature) {
                return CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
            }
            return kCLLocationCoordinate2DInvalid
        }()

        var iconImage: UIImage? = iconImage(mapItem: mapItem, zoom: zoom)
        
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
    
    public static var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        return cache
    }()
    
    func iconImage(mapItem: ObservationMapItem, zoom: Int) -> UIImage? {
        let w = WatchDog(named: "icon image")
        if let iconPath = mapItem.iconPath {
            if let image = ObservationMapImage.imageCache.object(forKey: "\(iconPath)/\(zoom)" as NSString) {
                return image
            }
            if let image = UIImage(contentsOfFile: iconPath) {
                let widthScale = max(0.3, (CGFloat(zoom) / 18.0)) * 35 * UIScreen.main.scale
                let scaledImage = image.aspectResize(to: CGSize(width: widthScale, height: image.size.height / (image.size.width / widthScale)))
                scaledImage.accessibilityIdentifier = iconPath
                ObservationMapImage.imageCache.setObject(scaledImage, forKey: "\(iconPath)/\(zoom)" as NSString)
                return scaledImage
            }
        }
        return nil
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
