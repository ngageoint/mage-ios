//
//  OnlineLayerMap.swift
//  MAGE
//
//  Created by Daniel Barela on 2/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import MapFramework

class OnlineLayerMapMixin: NSObject, MapMixin {
    var mapView: MKMapView?
    var mapState: MapState?
    var onlineLayers: [NSNumber:MKTileOverlay] = [:]
    
    func cleanupMixin() {
        UserDefaults.standard.removeObserver(self, forKeyPath: "selectedOnlineLayers")
    }
    
    func removeMixin(mapView: MKMapView, mapState: MapState) {

    }

    func updateMixin(mapView: MKMapView, mapState: MapState) {

    }

    func setupMixin(mapView: MKMapView, mapState: MapState) {
        self.mapView = mapView
        self.mapState = mapState
        UserDefaults.standard.addObserver(self, forKeyPath: "selectedOnlineLayers", options: [.new], context: nil)
        updateOnlineLayers()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        updateOnlineLayers()
    }
    
    func updateOnlineLayers() {
        guard let currentEventId = Server.currentEventId() else {
            return
        }
        let onlineLayersPerEvent = UserDefaults.standard.selectedOnlineLayers ?? [:]
        var unselectedOnlineLayerIds: [NSNumber] = onlineLayers.map({ $0.key })
        var transparentLayers: [MKTileOverlay] = []
        var nonBaseLayers: [MKTileOverlay] = []
        var baseLayers: [MKTileOverlay] = []
        let onlineLayersInEvent = onlineLayersPerEvent[(Server.currentEventId() ?? -1).stringValue] ?? []
        
        for onlineLayerId in onlineLayersInEvent {
            if let onlineLayer = ImageryLayer.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", onlineLayerId, currentEventId)) {
                if let overlay: MKTileOverlay = {
                    guard let format = onlineLayer.format else {
                        return nil
                    }
                    if format == "WMS" {
                        if let url = onlineLayer.url {
                            let wms = onlineLayer.options ?? [:]
                            print("Adding the WMS layer \(onlineLayer.name ?? "") to the map")
                            return WMSTileOverlay(url: url, andParameters: wms)
                        }
                    } else if format == "XYZ" {
                        if let url = onlineLayer.url {
                            print("Adding the XYZ layer \(onlineLayer.name ?? "") to the map url \(url)");
                            return XYZTileOverlay(urlTemplate: url)
                        }
                    } else if format == "TMS" {
                        if let url = onlineLayer.url {
                            print("Adding the TMS layer \(onlineLayer.name ?? "") to the map url \(url)");
                            return TMSTileOverlay(urlTemplate: url)
                        }
                    }
                    return nil
                }() {
                
                    if onlineLayers[onlineLayerId] == nil {
                        onlineLayers[onlineLayerId] = overlay
                        if let options = onlineLayer.options {
                            if let base = options[LayerOptionsKey.base.key] as? Bool, base == true {
                                baseLayers.append(overlay)
                            } else if let transparent = options[LayerOptionsKey.transparent.key] as? Bool, transparent == true {
                                transparentLayers.append(overlay)
                            } else {
                                nonBaseLayers.append(overlay)
                            }
                        } else if onlineLayer.base {
                            baseLayers.append(overlay)
                        } else {
                            nonBaseLayers.append(overlay)
                        }
                    }
                }
            }
            
            if let index = unselectedOnlineLayerIds.firstIndex(of: onlineLayerId) {
                unselectedOnlineLayerIds.remove(at: index)
            }
        }
        
        // Add the layers in the proper order ot the map
        for overlay in baseLayers {
            mapView?.addOverlay(overlay)
        }
        for overlay in nonBaseLayers {
            mapView?.addOverlay(overlay)
        }
        for overlay in transparentLayers {
            mapView?.addOverlay(overlay)
        }
        
        for unselectedOnlineLayerId in unselectedOnlineLayerIds {
            if let overlay = onlineLayers[unselectedOnlineLayerId] {
                mapView?.removeOverlay(overlay)
                onlineLayers.removeValue(forKey: unselectedOnlineLayerId)
            }
        }
    }
}
