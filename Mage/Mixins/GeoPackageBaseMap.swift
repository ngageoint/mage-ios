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

    func setupMixin() {
        addBaseMap()
    }
    
    func addBaseMap() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  return
              }
        
        if UITraitCollection.current.userInterfaceStyle == .dark {
            mapView?.removeOverlay(backgroundOverlay)
            mapView?.addOverlay(darkBackgroundOverlay, level: .aboveRoads)
        } else {
            mapView?.removeOverlay(darkBackgroundOverlay)
            mapView?.addOverlay(backgroundOverlay, level: .aboveRoads)
        }
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
