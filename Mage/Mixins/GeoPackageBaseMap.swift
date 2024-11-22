//
//  GeoPackageBaseMap.swift
//  MAGE
//
//  Created by Daniel Barela on 12/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework

protocol GeoPackageBaseMap {
    var mapView: MKMapView? { get set }
    var geoPackageBaseMapMixin: GeoPackageBaseMapMixin? { get set }
}

class GeoPackageBaseMapMixin: NSObject, MapMixin {
    weak var mapView: MKMapView?
    var gridOverlay: MKTileOverlay?
    
    init(mapView: MKMapView?) {
        self.mapView = mapView
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "mapType")
        UserDefaults.standard.removeObserver(self, forKeyPath: "gridType")
        UserDefaults.standard.removeObserver(self, forKeyPath: "mapShowTraffic")
    }

    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        UserDefaults.standard.addObserver(self, forKeyPath: "mapType", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "gridType", options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "mapShowTraffic", options: .new, context: nil)
        Task { [weak self] in
            await self?.addBaseMap()
        }
    }
    
    func renderer(overlay: MKOverlay) -> MKOverlayRenderer? {
        if let overlay = overlay as? BaseMapOverlay {
            return standardRenderer(overlay: overlay)
        }
        return nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        Task { [weak self] in
            await self?.addBaseMap()
        }
    }
    
    @MainActor
    func addBaseMap() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  return
              }
        mapView?.removeOverlay(darkBackgroundOverlay)
        mapView?.removeOverlay(backgroundOverlay)
        
        if UserDefaults.standard.mapType == 3 {
            let overrideStyle = mapView?.window?.overrideUserInterfaceStyle ?? UITraitCollection.current.userInterfaceStyle
            let style = overrideStyle == .unspecified ? UITraitCollection.current.userInterfaceStyle : overrideStyle
            if style == .dark {
                mapView?.addOverlay(darkBackgroundOverlay, level: .aboveRoads)
            } else {
                mapView?.addOverlay(backgroundOverlay, level: .aboveRoads)
            }
        } else {
            mapView?.mapType = MKMapType(rawValue: UInt(UserDefaults.standard.mapType)) ?? .standard
        }
        
        if gridOverlay != nil {
            mapView?.removeOverlay(gridOverlay!)
        }
        switch GridType(rawValue: UserDefaults.standard.gridType) {
        case .GARS:
            gridOverlay = GridSystems.garsTileOverlay()
            break;
        case .MGRS:
            gridOverlay = GridSystems.mgrsTileOverlay()
            break;
        default:
            gridOverlay = nil
        }
        if gridOverlay != nil {
            mapView?.addOverlay(gridOverlay!)
        }
        
        mapView?.showsTraffic = UserDefaults.standard.mapShowTraffic && mapView?.mapType != .satellite && UserDefaults.standard.mapType != 3
    }
    
    func traitCollectionUpdated(previous: UITraitCollection?) {
        if let previous = previous, previous.hasDifferentColorAppearance(comparedTo: UITraitCollection.current) {
            Task { [weak self] in
                await self?.addBaseMap()
            }
        } else if previous == nil {
            Task { [weak self] in
                await self?.addBaseMap()
            }
        }
    }
    
}
