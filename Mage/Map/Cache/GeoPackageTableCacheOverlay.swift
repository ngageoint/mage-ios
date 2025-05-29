//
//  GeoPackageTableCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

class GeoPackageTableCacheOverlay: CacheOverlay {
    var tileOverlay: MKTileOverlay?
    var parent: CacheOverlay?
    var geoPackage: String
    var count: Int
    var minZoom: Int
    var maxZoom: Int
    
    init(name: String, geoPackage: String, cacheName: String, type: CacheOverlayType, count: Int, minZoom: Int, maxZoom: Int) {
        self.geoPackage = geoPackage
        self.count = count
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        super.init(name: name, cacheName: cacheName, type: type, supportsChildren: false)
        self.isChild = true
    }
    
    override func getParent() -> CacheOverlay? {
        return parent
    }
    
    override func removeFromMap(mapView: MKMapView) {
        if tileOverlay != nil {
            mapView.removeOverlay(tileOverlay!)
            tileOverlay = nil
        }
    }
}

