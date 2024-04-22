//
//  DataSourceImage.swift
//
//
//  Created by Daniel Barela on 3/14/24.
//

import Foundation
import Kingfisher
import CoreGraphics
import CoreLocation
import UIKit
import DataSourceDefinition
import UIImageExtensions

public protocol DataSourceImage {
    static var dataSource: any DataSourceDefinition { get }
    static var imageCache: Kingfisher.ImageCache { get }
    @discardableResult
    func image(
        context: CGContext?,
        zoom: Int,
        tileBounds: MapBoundingBox,
        tileSize: Double
    ) -> [UIImage]
}

public extension DataSourceImage {
    static var imageCache: Kingfisher.ImageCache {
        Kingfisher.ImageCache(name: dataSource.key)
    }

    static func defaultCircleImage(dataSource: any DataSourceDefinition) -> [UIImage] {
        var images: [UIImage] = []
        if let circleImage = CircleImage(color: dataSource.color, radius: 40 * UIScreen.main.scale, fill: true) {
            images.append(circleImage)
            if let image = dataSource.image,
               let dataSourceImage = image.aspectResize(
                to: CGSize(width: circleImage.size.width / 1.5, height: circleImage.size.height / 1.5))
                .withRenderingMode(.alwaysTemplate)
                .maskWithColor(color: UIColor.white) {
                images.append(dataSourceImage)
            }
        }
        return images
    }

    func defaultMapImage(
        marker: Bool,
        zoomLevel: Int,
        pointCoordinate: CLLocationCoordinate2D,
        tileBounds3857: MapBoundingBox? = nil,
        context: CGContext? = nil,
        tileSize: Double
    ) -> [UIImage] {
        // zoom level 36 is a temporary hack to draw a large image for a real map marker
        if zoomLevel == 36 {
            return Self.defaultCircleImage(dataSource: Self.dataSource)
        }

        var images: [UIImage] = []
        var radius = CGFloat(zoomLevel) / 3.0 * UIScreen.main.scale * Self.dataSource.imageScale

        if let tileBounds3857 = tileBounds3857, context != nil {
            // have to do this b/c an ImageRenderer will automatically do this
            radius *= UIScreen.main.scale
            let coordinate = pointCoordinate
            if CLLocationCoordinate2DIsValid(coordinate) {
                let pixel = coordinate.toPixel(
                    zoomLevel: zoomLevel,
                    swCorner: tileBounds3857.swCorner,
                    neCorner: tileBounds3857.neCorner,
                    tileSize: tileSize)
                let circle = UIBezierPath(
                    arcCenter: pixel,
                    radius: radius,
                    startAngle: 0,
                    endAngle: 2 * CGFloat.pi,
                    clockwise: true)
                circle.lineWidth = 0.5
                Self.dataSource.color.setStroke()
                circle.stroke()
                Self.dataSource.color.setFill()
                circle.fill()
                if let dataSourceImage = Self.dataSource.image?.aspectResize(
                    to: CGSize(width: radius * 2.0 / 1.5, height: radius * 2.0 / 1.5))
                    .withRenderingMode(.alwaysTemplate).maskWithColor(color: UIColor.white) {
                    dataSourceImage.draw(
                        at: CGPoint(
                            x: pixel.x - dataSourceImage.size.width / 2.0,
                            y: pixel.y - dataSourceImage.size.height / 2.0))
                }
            }
        } else {
            if let image = CircleImage(color: Self.dataSource.color, radius: radius, fill: true) {
                images.append(image)
                if let dataSourceImage = Self.dataSource.image?.aspectResize(
                    to: CGSize(
                        width: image.size.width / 1.5,
                        height: image.size.height / 1.5)).withRenderingMode(.alwaysTemplate)
                    .maskWithColor(color: UIColor.white) {
                    images.append(dataSourceImage)
                }
            }
        }
        return images
    }

    func drawImageIntoTile(
        mapImage: UIImage,
        latitude: Double,
        longitude: Double,
        tileBounds3857: MapBoundingBox,
        tileSize: Double
    ) {
        let object3857Location =
        coord4326To3857(
            longitude: longitude,
            latitude: latitude)
        let xPosition = (
            ((object3857Location.x - tileBounds3857.swCorner.x) /
             (tileBounds3857.neCorner.x - tileBounds3857.swCorner.x)
            )  * tileSize)
        let yPosition = tileSize - (
            ((object3857Location.y - tileBounds3857.swCorner.y)
             / (tileBounds3857.neCorner.y - tileBounds3857.swCorner.y)
            ) * tileSize)
        mapImage.draw(
            in: CGRect(
                x: (xPosition - (mapImage.size.width / 2)),
                y: (yPosition - (mapImage.size.height / 2)),
                width: mapImage.size.width,
                height: mapImage.size.height
            )
        )
    }

    func coord4326To3857(longitude: Double, latitude: Double) -> (x: Double, y: Double) {
        let a = 6378137.0
        let lambda = longitude / 180 * Double.pi
        let phi = latitude / 180 * Double.pi
        let x = a * lambda
        let y = a * log(tan(Double.pi / 4 + phi / 2))

        return (x: x, y: y)
    }

    func coord3857To4326(y: Double, x: Double) -> (lat: Double, lon: Double) {
        let a = 6378137.0
        let distance = -y / a
        let phi = Double.pi / 2 - 2 * atan(exp(distance))
        let lambda = x / a
        let lat = phi / Double.pi * 180
        let lon = lambda / Double.pi * 180

        return (lat: lat, lon: lon)
    }
}
