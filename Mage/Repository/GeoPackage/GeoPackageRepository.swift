//
//  GeoPackageRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import geopackage_ios
import ExceptionCatcher

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
    
    var darkBackgroundOverlay: BaseMapOverlay?
    var backgroundOverlay: BaseMapOverlay?
    var darkBackgroundGeoPackage: GPKGGeoPackage?
    var backgroundGeoPackage: GPKGGeoPackage?
    
    func cleanupBackgroundGeoPackages() {
        self.backgroundGeoPackage?.close()
        self.darkBackgroundGeoPackage?.close()
        self.backgroundGeoPackage = nil
        self.darkBackgroundGeoPackage = nil
        self.backgroundOverlay?.cleanup()
        self.backgroundOverlay = nil
        self.darkBackgroundOverlay?.cleanup()
        self.darkBackgroundOverlay = nil
        
        CacheOverlays.getInstance().remove(byCacheName: "countries")
        CacheOverlays.getInstance().remove(byCacheName: "countries_dark")
    }
    
    func getBaseMap() -> BaseMapOverlay? {
        if backgroundOverlay != nil {
            return backgroundOverlay
        }
        
        // Add the GeoPackage caches
        guard let manager = GPKGGeoPackageFactory.manager() else {
            return nil
        }
        let countriesGeoPackagePath = Bundle.main.path(forResource: "countries", ofType: "gpkg")
        NSLog("Countries GeoPackage path \(countriesGeoPackagePath ?? "no path")")
        do {
            try ExceptionCatcher.catch {
                if !manager.exists("countries") {
                    manager.importGeoPackage(fromPath: countriesGeoPackagePath)
                }
            }
        } catch {
            // probably was already imported and that is fine
            print(error)
        }
        
        self.backgroundGeoPackage = manager.open("countries")
        if let backgroundGeoPackage = self.backgroundGeoPackage {
            do {
                try ExceptionCatcher.catch {
                    let featureDao = backgroundGeoPackage.featureDao(withTableName: "countries")
                    
                    // If indexed, add as a tile overlay
                    let featureTiles = GPKGFeatureTiles(geoPackage: backgroundGeoPackage, andFeatureDao: featureDao)
                    featureTiles?.indexManager = GPKGFeatureIndexManager(geoPackage: backgroundGeoPackage, andFeatureDao: featureDao)
                    
                    self.backgroundOverlay = BaseMapOverlay(featureTiles: featureTiles)
                    self.backgroundOverlay?.minZoom = 0
                    self.backgroundOverlay?.darkTheme = false
                    
                    self.backgroundOverlay?.canReplaceMapContent = true
                }
            } catch {
                NSLog("Exception initializing the base map GP \(error)")
            }
        }
        
        return self.backgroundOverlay
    }
    
    func getDarkBaseMap() -> BaseMapOverlay? {
        if darkBackgroundOverlay != nil {
            return darkBackgroundOverlay
        }
        
        // Add the GeoPackage caches
        guard let manager = GPKGGeoPackageFactory.manager() else {
            return nil
        }
        let countriesGeoPackagePath = Bundle.main.path(forResource: "countries_dark", ofType: "gpkg")
        NSLog("Countries GeoPackage path \(countriesGeoPackagePath ?? "no path")")
        do {
            try ExceptionCatcher.catch {
                if !manager.exists("countries_dark") {
                    manager.importGeoPackage(fromPath: countriesGeoPackagePath)
                }
            }
        } catch {
            // probably was already imported and that is fine
            print(error)
        }
        
        self.darkBackgroundGeoPackage = manager.open("countries_dark")
        if let backgroundGeoPackage = self.darkBackgroundGeoPackage {
            do {
                try ExceptionCatcher.catch {
                    let featureDao = backgroundGeoPackage.featureDao(withTableName: "countries")
                    
                    // If indexed, add as a tile overlay
                    let featureTiles = GPKGFeatureTiles(geoPackage: backgroundGeoPackage, andFeatureDao: featureDao)
                    featureTiles?.indexManager = GPKGFeatureIndexManager(geoPackage: backgroundGeoPackage, andFeatureDao: featureDao)
                    
                    self.darkBackgroundOverlay = BaseMapOverlay(featureTiles: featureTiles)
                    self.darkBackgroundOverlay?.minZoom = 0
                    self.darkBackgroundOverlay?.darkTheme = false
                    
                    self.darkBackgroundOverlay?.canReplaceMapContent = true
                }
            } catch {
                NSLog("Exception initializing the base map GP \(error)")
            }
        }
        
        return self.darkBackgroundOverlay
    }
    
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
            return GeoPackageFeatureItem(maxFeaturesReached: true, featureCount: key.featureCount, geoPackageName: key.geoPackageName, layerName: key.layerName, tableName: key.tableName)
        }
    }
}
