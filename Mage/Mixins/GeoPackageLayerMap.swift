//
//  GeoPackageLayerMap.swift
//  MAGE
//
//  Created by Daniel Barela on 1/29/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import geopackage_ios

protocol GeoPackageLayerMap {
    var mapView: MKMapView? { get set }
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin? { get set }
}

class GeoPackageLayerMapMixin: NSObject, MapMixin {
    var geopackageImportedObserver: AnyObject?

    var geoPackageLayerMap: GeoPackageLayerMap?
    var mapView: MKMapView?
    
    var geoPackageManager: GPKGGeoPackageManager?
    var geoPackageCache: GPKGGeoPackageCache?
    
    var geoPackage: GeoPackage?
    
    init(geoPackageLayerMap: GeoPackageLayerMap) {
        self.geoPackageLayerMap = geoPackageLayerMap
        self.mapView = geoPackageLayerMap.mapView
    }
    
    func setupMixin() {
        guard let mapView = mapView else {
            return
        }
        geoPackage = GeoPackage(mapView: mapView)
        
        CacheOverlays.getInstance().register(self)
        geopackageImportedObserver = NotificationCenter.default.addObserver(forName: .GeoPackageImported, object: nil, queue: .main) { [weak self] notification in
            self?.updateGeoPackageLayers()
        }
        updateGeoPackageLayers()
    }
    
    func cleanupMixin() {
        CacheOverlays.getInstance().unregisterListener(self)
        if let geopackageImportedObserver = geopackageImportedObserver {
            NotificationCenter.default.removeObserver(geopackageImportedObserver)
        }
        geopackageImportedObserver = nil
    }
    
    func updateGeoPackageLayers() {
        geoPackage?.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
    }
    
    func items(at location: CLLocationCoordinate2D) -> [Any]? {
        return geoPackage?.getFeaturesAtTap(location)
    }
}

extension GeoPackageLayerMapMixin : CacheOverlayListener {
    func cacheOverlaysUpdated(_ cacheOverlays: [CacheOverlay]!) {
        updateGeoPackageLayers()
    }
}
