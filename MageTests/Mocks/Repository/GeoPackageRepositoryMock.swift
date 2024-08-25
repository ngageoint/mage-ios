//
//  GeoPackageRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class GeoPackageRepositoryMock: GeoPackageRepository {
    var items: [GeoPackageFeatureItem] = []
    
    override func getGeoPackageFeatureItem(key: GeoPackageFeatureKey) -> GeoPackageFeatureItem? {
        items.first { item in
            item.featureId == key.featureId
        }
    }
    
    override func getBaseMap() -> BaseMapOverlay? {
        return nil
    }
    
    override func getDarkBaseMap() -> BaseMapOverlay? {
        return nil
    }
    
    override func cleanupBackgroundGeoPackages() {
        
    }
}
