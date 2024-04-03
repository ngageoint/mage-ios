//
//  TileRepository.swift
//
//
//  Created by Daniel Barela on 3/14/24.
//

import Foundation
import DataSourceDefinition
import Kingfisher
import CoreLocation
import UIKit
import MapKit

public protocol TileRepository {
    var dataSource: any DataSourceDefinition { get }
    var cacheSourceKey: String? { get }

    var imageCache: Kingfisher.ImageCache? { get }

    var filterCacheKey: String { get }
    var alwaysShow: Bool { get }

    func getTileableItems(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double,
        latitudePerPixel: Double,
        longitudePerPixel: Double,
        zoom: Int,
        precise: Bool
    ) async -> [DataSourceImage]

    func getItemKeys(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double,
        precise: Bool
    ) async -> [String]

    func clearCache(completion: @escaping () -> Void)
    func getMaximumIconHeightToWidthRatio() -> CGSize
    func getToleranceInPixels(zoom: Int) -> CGSize
}

public extension TileRepository {
    func clearCache(completion: @escaping () -> Void) {
        if let imageCache = self.imageCache {
            imageCache.clearCache(completion: completion)
        } else {
            completion()
        }
    }

    func markerHitTest(
        location: CLLocationCoordinate2D,
        hitBoxSouthWest: CLLocationCoordinate2D? = nil,
        hitBoxNorthEast: CLLocationCoordinate2D? = nil,
        zoom: Int,
        tileProvider: DataSourceTileOverlay
    ) async -> Bool {
        let tile = location.toTile(zoom: zoom)

        let minTileLon = CLLocationCoordinate2D.longitudeFromTile(x: tile.x, zoom: zoom)
        let maxTileLon = CLLocationCoordinate2D.longitudeFromTile(x: tile.x+1, zoom: zoom)
        let minTileLat = CLLocationCoordinate2D.latitudeFromTile(y: tile.y+1, zoom: zoom)
        let maxTileLat = CLLocationCoordinate2D.latitudeFromTile(y: tile.y, zoom: zoom)

        let neCorner3857 = CLLocationCoordinate2D(latitude: maxTileLat, longitude: maxTileLon).degreesToMeters()
        let swCorner3857 = CLLocationCoordinate2D(latitude: minTileLat, longitude: minTileLon).degreesToMeters()

        // these are the min max x y in meters
        let minTileX = swCorner3857.x
        let minTileY = swCorner3857.y
        let maxTileX = neCorner3857.x
        let maxTileY = neCorner3857.y

        // The pixels that they touched
        var minPixelX: Int = 0
        var maxPixelX: Int = 512
        var minPixelY: Int = 0
        var maxPixelY: Int = 512
        if let hitBoxNorthEast = hitBoxNorthEast, let hitBoxSouthWest = hitBoxSouthWest {
            let nePixel = CLLocationCoordinate2D(latitude: hitBoxNorthEast.latitude, longitude: hitBoxNorthEast.longitude)
                .toPixel(
                    zoomLevel: zoom,
                    swCorner: (x: minTileX, y: minTileY),
                    neCorner: (x: maxTileX, y: maxTileY),
                    tileSize: 512.0
                )
            let swPixel = CLLocationCoordinate2D(latitude: hitBoxSouthWest.latitude, longitude: hitBoxSouthWest.longitude)
                .toPixel(
                    zoomLevel: zoom,
                    swCorner: (x: minTileX, y: minTileY),
                    neCorner: (x: maxTileX, y: maxTileY),
                    tileSize: 512.0
                )
            minPixelX = Int(nePixel.x.rounded(.down))
            maxPixelX = Int(swPixel.x.rounded(.up))
            minPixelY = Int(nePixel.y.rounded(.down))
            maxPixelY = Int(swPixel.y.rounded(.up))

        } else {
            let pixel = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                .toPixel(
                    zoomLevel: zoom,
                    swCorner: (x: minTileX, y: minTileY),
                    neCorner: (x: maxTileX, y: maxTileY),
                    tileSize: 512.0
                )
            minPixelX = Int(pixel.x.rounded(.down))
            maxPixelX = Int(pixel.x.rounded(.up))
            minPixelY = Int(pixel.y.rounded(.down))
            maxPixelY = Int(pixel.y.rounded(.up))
        }

        let scale = await UIScreen.main.scale
        let data: Data? = await withCheckedContinuation { continuation in
            tileProvider.loadTile(at: MKTileOverlayPath(x: tile.x, y: tile.y, z: zoom, contentScaleFactor: scale)) { data, error in
                continuation.resume(returning: data)
            }
        }

        guard let data = data, let imageWithAlphaChannel = UIImage(data: data) else {
            return false
        }
        return imageWithAlphaChannel.hasNonTransparentPixelInBounds(
            minPoint: CGPoint(x: minPixelX, y: minPixelY),
            maxPoint: CGPoint(x: maxPixelX, y: maxPixelY)
        )
    }
}
