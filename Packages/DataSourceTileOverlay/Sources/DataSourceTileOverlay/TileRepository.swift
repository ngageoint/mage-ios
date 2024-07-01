//
//  TileRepository.swift
//
//
//  Created by Daniel Barela on 3/14/24.
//

import Foundation
import DataSourceDefinition
import DebugUtilities
import Kingfisher
import CoreLocation
import UIKit
import MapKit
import CLLocationCoordinate2DExtensions
import Combine

public protocol TileRepository {
    var dataSource: any DataSourceDefinition { get }
    var cacheSourceKey: String? { get }

    var imageCache: Kingfisher.ImageCache? { get }

    var filterCacheKey: String { get }
    var alwaysShow: Bool { get }

    var refreshPublisher: AnyPublisher<Date, Never>? { get }
    var refreshSubject: PassthroughSubject<Date, Never>? { get }

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
        latitudePerPixel: Double,
        longitudePerPixel: Double,
        zoom: Int,
        precise: Bool,
        distanceTolerance: Double
    ) async -> [String]

    func clearCache(regions: [MKCoordinateRegion]?) async
}

public extension TileRepository {

    var refreshPublisher: AnyPublisher<Date, Never>? {
        nil
    }

    var refreshSubject: PassthroughSubject<Date, Never>? {
        nil
    }

    func clearCache() async {
        await clearCache(regions: nil)
    }

    func clearCache(regions: [MKCoordinateRegion]? = nil) async {
        if let imageCache = self.imageCache {
            var keysToClear: Set<String> = Set<String>()
            if let regions = regions {
                for region in regions {
                    let intersectingTileBounds = region.intersectingTileBounds(minZoom: 0, maxZoom: 18)
                    for (key, value) in intersectingTileBounds {
                        let southWest = value.southWest
                        let northEast = value.northEast
                        for x in southWest.x...northEast.x {
                            for y in southWest.y...northEast.y {
                                keysToClear.insert("\(cacheSourceKey ?? "_dc")/\(key)/\(x)/\(y)")
                            }
                        }
                    }
                }
                for key in keysToClear {
                    await withCheckedContinuation { continuation in
                        imageCache.removeImage(forKey: key, completionHandler: continuation.resume)
                    }
                }
            } else {
                await withCheckedContinuation { continuation in
                    imageCache.clearCache(completion: continuation.resume)
                }
            }
        }
    }

    func markerHitTest(
        location: CLLocationCoordinate2D,
        hitBoxSouthWest: CLLocationCoordinate2D? = nil,
        hitBoxNorthEast: CLLocationCoordinate2D? = nil,
        zoom: Int,
        tileProvider: DataSourceTileOverlay
    ) async -> Bool {
        let methodWatchDog = WatchDog(named: "Marker Hit Test")
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

    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        return nil
    }

    func standardRenderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        // standard renderers
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = .black
            renderer.lineWidth = 1
            return renderer
        } else if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .black
            renderer.lineWidth = 50
            return renderer
        }
        return nil
    }
}
