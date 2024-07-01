//
//  GeoPackageRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import geopackage_ios

private struct GeoPackageRepositoryProviderKey: InjectionKey {
    static var currentValue: GeoPackageRepository = GeoPackageRepository()
}

extension InjectedValues {
    var geoPackageRepository: GeoPackageRepository {
        get { Self[GeoPackageRepositoryProviderKey.self] }
        set { Self[GeoPackageRepositoryProviderKey.self] = newValue }
    }
}

class GeoPackageRepository: ObservableObject {
    
    func getGeoPackageFeatureItem(key: GeoPackageFeatureKey) -> GeoPackageFeatureItem? {
        if !key.maxFeaturesFound {
            guard
                let manager = GPKGGeoPackageFactory.manager(),
                let geoPackage = manager.open(key.geoPackageName),
                let featureDao = geoPackage.featureDao(withTableName: key.tableName),
                let featureRow = featureDao.query(forIdRow: Int32(key.featureId)) as? GPKGFeatureRow
            else {
                return nil
            }
            let item = GeoPackageFeatureItem(featureRow: featureRow, geoPackage: geoPackage, layerName: key.layerName, projection: featureDao.projection)
            return item
        } else {
            return GeoPackageFeatureItem(maxFeaturesReached: true, featureCount: key.featureCount, layerName: key.layerName)
        }
    }
}
