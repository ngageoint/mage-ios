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
        "\(tileRepository.cacheSourceKey ?? "_dc")/\(path.z)/\(path.x)/\(path.y)/\(tileRepository.filterCacheKey)"
    }

    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let zoomLevel = path.z

            let minTileLon = longitude(x: path.x, zoom: path.z)
            let maxTileLon = longitude(x: path.x+1, zoom: path.z)
            let minTileLat = latitude(y: path.y+1, zoom: path.z)
            let maxTileLat = latitude(y: path.y, zoom: path.z)

            let neCorner3857 = CLLocationCoordinate2D(latitude: maxTileLat, longitude: maxTileLon).degreesToMeters()
            let swCorner3857 = CLLocationCoordinate2D(latitude: minTileLat, longitude: minTileLon).degreesToMeters()

            let minTileX = swCorner3857.x
            let minTileY = swCorner3857.y
            let maxTileX = neCorner3857.x
            let maxTileY = neCorner3857.y

            // border the tile by 40 miles since that is as far as any light i have seen.  if that is wrong, update
            // border has to be at least 30 pixels as well
            let nauticalMilesMeasurement = NSMeasurement(doubleValue: 40.0, unit: UnitLength.nauticalMiles)
            let metersMeasurement = nauticalMilesMeasurement.converting(to: UnitLength.meters).value

            let tolerance = max(metersMeasurement, ((maxTileY - minTileY) / self.tileSize.width) * 30.0)

            let neCornerTolerance = CLLocationCoordinate2D.metersToDegrees(
                x: maxTileX + tolerance,
                y: maxTileY + tolerance)
            let swCornerTolerance = CLLocationCoordinate2D.metersToDegrees(
                x: minTileX - tolerance,
                y: minTileY - tolerance)

            drawTile(
                tileBounds3857: MapBoundingBox(
                    swCorner: (x: swCorner3857.x, y: swCorner3857.y),
                    neCorner: (x: neCorner3857.x, y: neCorner3857.y)),
                queryBounds: MapBoundingBox(
                    swCorner: (x: swCornerTolerance.x, y: swCornerTolerance.y),
                    neCorner: (x: neCornerTolerance.x, y: neCornerTolerance.y)),
                zoomLevel: zoomLevel,
                cacheKey: cacheKey,
                handler: handler)
        }
    }

    func drawTile(
        tileBounds3857: MapBoundingBox,
        queryBounds: MapBoundingBox,
        zoomLevel: Int,
        cacheKey: String,
        handler: @escaping (Result<Data, Error>) -> Void
    ) {

        Task {
            let items = await tileRepository.getTileableItems(
                minLatitude: queryBounds.swCorner.y,
                maxLatitude: queryBounds.neCorner.y,
                minLongitude: queryBounds.swCorner.x,
                maxLongitude: queryBounds.neCorner.x
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

    func longitude(x: Int, zoom: Int) -> Double {
        return Double(x) / pow(2.0, Double(zoom)) * 360.0 - 180.0
    }

    func latitude(y: Int, zoom: Int) -> Double {
        let yLocation = Double.pi - 2.0 * Double.pi * Double(y) / pow(2.0, Double(zoom))
        return 180.0 / Double.pi * atan(0.5 * (exp(yLocation) - exp(-yLocation)))
    }
}
