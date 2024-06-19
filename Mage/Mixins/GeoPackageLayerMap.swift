//
//  GeoPackageLayerMap.swift
//  MAGE
//
//  Created by Daniel Barela on 1/29/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework
import geopackage_ios

protocol GeoPackageLayerMap {
    var mapView: MKMapView? { get set }
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin? { get set }
}

class GeoPackageLayerMapMixin: NSObject, MapMixin {
    var geopackageImportedObserver: AnyObject?

    var geoPackageLayerMap: GeoPackageLayerMap
    
    var geoPackageManager: GPKGGeoPackageManager?
    var geoPackageCache: GPKGGeoPackageCache?
    
    var geoPackage: GeoPackage?
    
    init(geoPackageLayerMap: GeoPackageLayerMap) {
        self.geoPackageLayerMap = geoPackageLayerMap
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        guard let mapView = geoPackageLayerMap.mapView else {
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
    
//    func items(
//        at location: CLLocationCoordinate2D,
//        mapView: MKMapView,
//        touchPoint: CGPoint
//    ) async -> [Any]? {
////    func items(at location: CLLocationCoordinate2D) -> [Any]? {
//        return geoPackage?.getFeaturesAtTap(location)
//    }
    
    func itemKeys(
        at location: CLLocationCoordinate2D,
        mapView: MKMapView,
        touchPoint: CGPoint
    ) async -> [String : [String]] {
        if let keys = geoPackage?.getFeatureKeys(atTap: location) {
            return [DataSources.geoPackage.key: keys.map({ key in
                key.toKey()
            })]
        }
        return [:]
    }
}

extension GeoPackageLayerMapMixin : CacheOverlayListener {
    func cacheOverlaysUpdated(_ cacheOverlays: [CacheOverlay]!) {
        updateGeoPackageLayers()
    }
}
