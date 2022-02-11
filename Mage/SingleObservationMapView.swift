//
//  SingleObservationMapView.swift
//  MAGE
//
//  Created by Daniel Barela on 2/10/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class SingleObservationMapView: MageMapView, FilteredObservationsMap {
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    
    var observation: Observation?
    
    public init(observation: Observation?, scheme: MDCContainerScheming?) {
        self.observation = observation
        super.init(scheme: scheme)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutView() {
        super.layoutView()
        
        if let mapView = mapView {
            filteredObservationsMapMixin = FilteredObservationsMapMixin(mapView: mapView, observation: observation, scheme: scheme)
            mapMixins.append(filteredObservationsMapMixin!)
        }
        
        initiateMapMixins()
    }
    
    override func removeFromSuperview() {
        filteredObservationsMapMixin = nil
    }
    
}
