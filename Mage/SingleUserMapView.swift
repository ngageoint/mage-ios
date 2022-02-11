//
//  SingleUserMap.swift
//  MAGE
//
//  Created by Daniel Barela on 2/10/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class SingleUserMapView: MageMapView, FilteredUsersMap, FilteredObservationsMap {
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    var filteredUsersMapMixin: FilteredUsersMapMixin?

    var user: User?
    
    public init(user: User?, scheme: MDCContainerScheming?) {
        self.user = user
        super.init(scheme: scheme)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutView() {
        super.layoutView()
        
        if let mapView = mapView {
            filteredUsersMapMixin = FilteredUsersMapMixin(filteredUsersMap: self, user: user, scheme: scheme)
            filteredObservationsMapMixin = FilteredObservationsMapMixin(mapView: mapView, user: user, scheme: scheme)
            mapMixins.append(filteredObservationsMapMixin!)
            mapMixins.append(filteredUsersMapMixin!)
        }

        initiateMapMixins()
    }
    
    override func removeFromSuperview() {
        filteredUsersMapMixin = nil
        filteredObservationsMapMixin = nil
    }
    
}
