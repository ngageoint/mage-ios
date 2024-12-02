//
//  GeoPackageCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

class GeoPackageCacheOverlay: CacheOverlay {
    public var filePath: String
    var cacheOverlays: [CacheOverlay] = []
    var layerId: String?
    
    public init(name: String, path: String, tables: [GeoPackageTableCacheOverlay]) {
        self.filePath = path
        super.init(name: name, type: CacheOverlayType.GEOPACKAGE, supportsChildren: true)
        self.iconImageName = "geopackage"
        
        for table in tables {
            table.parent = self
            if table.type == .GEOPACKAGE_FEATURE_TABLE {
                let featureTable = table as! GeoPackageFeatureTableCacheOverlay
                for linkedTile in featureTable.linkedTiles {
                    linkedTile.parent = self
                }
            }
            cacheOverlays.append(table)
        }
        
        let pathComponents = (filePath as NSString).pathComponents
        if pathComponents.count >= 3,
           pathComponents[pathComponents.count - 3] == "geopackages"
        {
            layerId = pathComponents[pathComponents.count - 2]
        }
    }
    
    override func removeFromMap(mapView: MKMapView) {
        for cacheOverlay in getChildren() {
            cacheOverlay.removeFromMap(mapView: mapView)
        }
    }
    
    override func getChildren() -> [CacheOverlay] {
        cacheOverlays
    }
}
