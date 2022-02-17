//
//  SingleFeatureMapView.swift
//  MAGE
//
//  Created by Daniel Barela on 2/16/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class SingleFeatureMapView: MageMapView, GeoPackageLayerMap, OnlineLayerMap, FilteredObservationsMap {
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin?
    var onlineLayerMapMixin: OnlineLayerMapMixin?
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    
    var _observation: Observation?
    var observation: Observation? {
        get {
            return _observation
        }
        set {
            _observation = newValue
            addFeature()
        }
    }
    
    var _sfgeometry: SFGeometry?
    var sfgeometry: SFGeometry? {
        get {
            return _sfgeometry
        }
        set {
            _sfgeometry = newValue
            addFeature()
        }
    }
    
    public init(observation: Observation?, scheme: MDCContainerScheming?) {
        super.init(scheme: scheme)
        self._observation = observation
    }
    
    public init(sfgeometry: SFGeometry?, scheme: MDCContainerScheming?) {
        super.init(scheme: scheme)
        self._sfgeometry = sfgeometry
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutView() {
        super.layoutView()
        
        if let mapView = self.mapView {
            onlineLayerMapMixin = OnlineLayerMapMixin(onlineLayerMap: self, scheme: scheme)
            geoPackageLayerMapMixin = GeoPackageLayerMapMixin(geoPackageLayerMap: self)
            filteredObservationsMapMixin = FilteredObservationsMapMixin(mapView: mapView, user: nil, observation: nil, scheme: scheme)
            mapMixins.append(geoPackageLayerMapMixin!)
            mapMixins.append(onlineLayerMapMixin!)
            mapMixins.append(filteredObservationsMapMixin!)
        }
        
        initiateMapMixins()
        
        addFeature()
    }
    
    override func removeFromSuperview() {
        cleanupMapMixins()
        geoPackageLayerMapMixin = nil
        onlineLayerMapMixin = nil
    }
    
    func addFeature() {
        if let observation = observation {
            filteredObservationsMapMixin?.updateObservation(observation: observation, zoom: true)
        } else if let sfgeometry = sfgeometry {
            // add the geometry to the map
        }
    }
    
}
