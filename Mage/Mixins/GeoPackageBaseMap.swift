//
//  GeoPackageBaseMap.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

protocol GeoPackageBaseMap {
    var mapView: MKMapView? { get set }
    var geoPackageBaseMapMixin: GeoPackageBaseMapMixin? { get set }
    func addBaseMap()
}

extension GeoPackageBaseMap {
    
    func addBaseMap() {
        geoPackageBaseMapMixin?.addBaseMap()
    }
}

class GeoPackageBaseMapMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    
    init(mapView: MKMapView?) {
        self.mapView = mapView
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "mapType")
        UserDefaults.standard.removeObserver(self, forKeyPath: "mapShowTraffic")
    }

    func setupMixin() {
        UserDefaults.standard.addObserver(self, forKeyPath: "mapType", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "mapShowTraffic", options: .new, context: nil)
        addBaseMap()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        addBaseMap()
    }
    
    func addBaseMap() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  return
              }
        
        if UserDefaults.standard.mapType == 3 {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                mapView?.removeOverlay(backgroundOverlay)
                mapView?.addOverlay(darkBackgroundOverlay, level: .aboveRoads)
            } else {
                mapView?.removeOverlay(darkBackgroundOverlay)
                mapView?.addOverlay(backgroundOverlay, level: .aboveRoads)
            }
        } else {
            mapView?.removeOverlay(darkBackgroundOverlay)
            mapView?.removeOverlay(backgroundOverlay)
            mapView?.mapType = MKMapType(rawValue: UInt(UserDefaults.standard.mapType)) ?? .standard
        }
        mapView?.showsTraffic = UserDefaults.standard.mapShowTraffic && mapView?.mapType != .satellite && UserDefaults.standard.mapType != 3
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        guard let overlay = overlay as? BaseMapOverlay else {
            return nil
        }
        return MKTileOverlayRenderer(overlay: overlay)
    }
    
    func traitCollectionUpdated(previous: UITraitCollection?) {
        addBaseMap()
    }
}
