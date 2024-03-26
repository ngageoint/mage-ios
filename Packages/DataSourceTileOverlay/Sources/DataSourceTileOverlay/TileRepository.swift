//
//  TileRepository.swift
//  
//
//  Created by Daniel Barela on 3/14/24.
//

import Foundation
import DataSourceDefinition
import Kingfisher

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
        maxLongitude: Double
    ) async -> [DataSourceImage]

    func getItemKeys(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) async -> [String]

    func clearCache(completion: @escaping () -> Void)
}

public extension TileRepository {
    func clearCache(completion: @escaping () -> Void) {
        if let imageCache = self.imageCache {
            imageCache.clearCache(completion: completion)
        } else {
            completion()
        }
    }
}
