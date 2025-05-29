//
//  SingleFeatureMapView.swift
//  MAGE
//
//  Created by Daniel Barela on 2/16/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class SingleFeatureMapView: MageMapView, GeoPackageLayerMap, SFGeometryMap {
    @Injected(\.observationMapItemRepository)
    var observationMapItemRepository: ObservationMapItemRepository
    
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin?
    var onlineLayerMapMixin: OnlineLayerMapMixin?
    var observationMapMixin: ObservationMap = ObservationMap()
    var sfGeometryMapMixin: SFGeometryMapMixin?
    
    var _observation: Observation?
    var observation: Observation? {
        get {
            return _observation
        }
        set {
            if let observationUri = newValue?.objectID.uriRepresentation() {
                observationMapMixin.viewModel?.mapFeatureRepository = ObservationMapFeatureRepository(observationUri: observationUri)
//                observationMapMixin.refresh()
//                if let mapView = mapView {
//                    observationMapMixin.refreshMap(mapState: mapState)
//                }
            }
            _observation = newValue
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
        
        onlineLayerMapMixin = OnlineLayerMapMixin()
        geoPackageLayerMapMixin = GeoPackageLayerMapMixin(geoPackageLayerMap: self)
        sfGeometryMapMixin = SFGeometryMapMixin(sfGeometryMap: self, sfGeometry: sfgeometry)
        mapMixins.append(onlineLayerMapMixin!)
        mapMixins.append(sfGeometryMapMixin!)
        mapMixins.append(observationMapMixin)

        initiateMapMixins()
        
        addFeature()
    }
    
    override func removeFromSuperview() {
        cleanupMapMixins()
        geoPackageLayerMapMixin = nil
        onlineLayerMapMixin = nil
        sfGeometryMapMixin = nil
    }
    
    func addFeature() {
//        if let observation = observation, let mapView = mapView {
//            observationMapMixin.updateMixin(mapView: mapView, mapState: mapState)
//        } else 
        if let sfgeometry = sfgeometry {
            // add the geometry to the map
            sfGeometryMapMixin?.sfGeometry = sfgeometry
            if let centroid = sfgeometry.centroid() {
                mapView?.setCenter(
                    CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue), animated: true
                )
            }
        }
    }
    
    override func applyTheme(scheme: MDCContainerScheming?) {
        super.applyTheme(scheme: scheme)
        addFeature()
    }
    
}
