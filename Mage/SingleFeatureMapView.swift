//
//  SingleFeatureMapView.swift
//  MAGE
//
//  Created by Daniel Barela on 2/16/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class SingleFeatureMapView: MageMapView, GeoPackageLayerMap, OnlineLayerMap, SingleObservationMap, SFGeometryMap {
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin?
    var onlineLayerMapMixin: OnlineLayerMapMixin?
    var singleObservationMapMixin: SingleObservationMapMixin?
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
        
        if let mapView = self.mapView {
            onlineLayerMapMixin = OnlineLayerMapMixin(onlineLayerMap: self, scheme: scheme)
            geoPackageLayerMapMixin = GeoPackageLayerMapMixin(geoPackageLayerMap: self)
            singleObservationMapMixin = SingleObservationMapMixin(mapView: mapView, observation: nil, scheme: scheme)
            sfGeometryMapMixin = SFGeometryMapMixin(sfGeometryMap: self, sfGeometry: sfgeometry, scheme: scheme)
            mapMixins.append(onlineLayerMapMixin!)
            mapMixins.append(singleObservationMapMixin!)
            mapMixins.append(sfGeometryMapMixin!)
        }
        
        initiateMapMixins()
        
        addFeature()
    }
    
    override func removeFromSuperview() {
        cleanupMapMixins()
        geoPackageLayerMapMixin = nil
        onlineLayerMapMixin = nil
        sfGeometryMapMixin = nil
        singleObservationMapMixin = nil
    }
    
    func addFeature() {
        if let observation = observation {
            singleObservationMapMixin?.updateObservation(observation: observation, zoom: true)
        } else if let sfgeometry = sfgeometry {
            // add the geometry to the map
            sfGeometryMapMixin?.sfGeometry = sfgeometry
        }
    }
    
}
