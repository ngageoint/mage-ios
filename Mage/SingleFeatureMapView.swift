//
//  SingleFeatureMapView.swift
//  MAGE
//
//  Created by Daniel Barela on 2/16/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class SingleFeatureMapView: MageMapView, GeoPackageLayerMap, OnlineLayerMap, FilteredObservationsMap, SFGeometryMap {
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin?
    var onlineLayerMapMixin: OnlineLayerMapMixin?
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    var sfGeometryMapMixin: SFGeometryMapMixin?
    
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
        self.scheme = scheme
    }
    
    public init(sfgeometry: SFGeometry?, scheme: MDCContainerScheming?) {
        super.init(scheme: scheme)
        self._sfgeometry = sfgeometry
        self.scheme = scheme
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutView() {
        super.layoutView()
        
        onlineLayerMapMixin = OnlineLayerMapMixin(onlineLayerMap: self)
        geoPackageLayerMapMixin = GeoPackageLayerMapMixin(geoPackageLayerMap: self)
        filteredObservationsMapMixin = SingleObservationMapMixin(filteredObservationsMap: self, observation: nil)
        sfGeometryMapMixin = SFGeometryMapMixin(sfGeometryMap: self, sfGeometry: sfgeometry)
        mapMixins.append(onlineLayerMapMixin!)
        mapMixins.append(filteredObservationsMapMixin!)
        mapMixins.append(sfGeometryMapMixin!)
        
        initiateMapMixins()
        
        addFeature()
    }
    
    override func removeFromSuperview() {
        cleanupMapMixins()
        geoPackageLayerMapMixin = nil
        onlineLayerMapMixin = nil
        sfGeometryMapMixin = nil
        filteredObservationsMapMixin = nil
    }
    
    func addFeature() {
        if let observation = observation {
            filteredObservationsMapMixin?.updateObservation(observation: observation, zoom: true)
        } else if let sfgeometry = sfgeometry {
            // add the geometry to the map
            sfGeometryMapMixin?.sfGeometry = sfgeometry
        }
    }
    
}
