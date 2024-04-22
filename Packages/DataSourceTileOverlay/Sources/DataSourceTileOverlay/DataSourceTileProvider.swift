//
//  DataSourceTileProvider.swift
//
//
//  Created by Daniel Barela on 3/14/24.
//

import Foundation
import Kingfisher
import MapKit
import CLLocationCoordinate2DExtensions

enum DataTileError: Error {
    case zeroObjects
    case notFound
    case unexpected(code: Int)
}

extension DataTileError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .zeroObjects:
            return "There were no objects for this image."
        case .notFound:
            return "The specified item could not be found."
        case .unexpected:
            return "An unexpected error occurred."
        }
    }
}

extension DataTileError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .zeroObjects:
            return NSLocalizedString(
                "There were no objects for this image.",
                comment: "Zero Objects"
            )
        case .notFound:
            return NSLocalizedString(
                "The specified item could not be found.",
                comment: "Resource Not Found"
            )
        case .unexpected:
            return NSLocalizedString(
                "An unexpected error occurred.",
                comment: "Unexpected Error"
            )
        }
    }
}

struct DataSourceTileProvider: ImageDataProvider {
    let tileRepository: TileRepository
    let path: MKTileOverlayPath
    var tileSize: CGSize = CGSize(width: 512, height: 512)

    var cacheKey: String {
        "\(tileRepository.cacheSourceKey ?? Date().formatted())"
    }

    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        Task(priority: .userInitiated) {
            let zoomLevel = path.z

            let minTileLon = CLLocationCoordinate2D.longitudeFromTile(x: path.x, zoom: path.z)
            let maxTileLon = CLLocationCoordinate2D.longitudeFromTile(x: path.x+1, zoom: path.z)
            let minTileLat = CLLocationCoordinate2D.latitudeFromTile(y: path.y+1, zoom: path.z)
            let maxTileLat = CLLocationCoordinate2D.latitudeFromTile(y: path.y, zoom: path.z)

            let neCorner3857 = CLLocationCoordinate2D(latitude: maxTileLat, longitude: maxTileLon).degreesToMeters()
            let swCorner3857 = CLLocationCoordinate2D(latitude: minTileLat, longitude: minTileLon).degreesToMeters()

            let latitudePerPixel: Double = (maxTileLat - minTileLat) / self.tileSize.height
            let longitudePerPixel: Double = (maxTileLon - minTileLon) / self.tileSize.width

            let tileBounds3857 = MapBoundingBox(
                swCorner: (x: swCorner3857.x, y: swCorner3857.y),
                neCorner: (x: neCorner3857.x, y: neCorner3857.y))
            let queryBounds = MapBoundingBox(
                swCorner: (x: minTileLon, y: minTileLat),
                neCorner: (x: maxTileLon, y: maxTileLat))

            let items = await tileRepository.getTileableItems(
                minLatitude: queryBounds.swCorner.y,
                maxLatitude: queryBounds.neCorner.y,
                minLongitude: queryBounds.swCorner.x,
                maxLongitude: queryBounds.neCorner.x,
                latitudePerPixel: latitudePerPixel,
                longitudePerPixel: longitudePerPixel,
                zoom: zoomLevel,
                precise: false
            )
            UIGraphicsBeginImageContext(self.tileSize)

            items.forEach { dataSourceImage in
                dataSourceImage.image(
                    context: UIGraphicsGetCurrentContext(),
                    zoom: zoomLevel,
                    tileBounds: tileBounds3857,
                    tileSize: tileSize.width
                )
            }

            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

            UIGraphicsEndImageContext()

            guard let cgImage = newImage.cgImage else {
                handler(.failure(DataTileError.notFound))
                return
            }
            let data = UIImage(cgImage: cgImage).pngData()
            if let data = data {
                handler(.success(data))
            } else {
                handler(.failure(DataTileError.notFound))
            }
        }
    }
}
