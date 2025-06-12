//
//  SingleUserMap.swift
//  MAGE
//
//  Created by Daniel Barela on 2/10/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class SingleUserMapView: MageMapView, FilteredUsersMap, FilteredObservationsMap, FollowUser {
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    var filteredUsersMapMixin: FilteredUsersMapMixin?
    var followUserMapMixin: FollowUserMapMixin?

    var user: User?
    
    public init(user: User?, scheme: AppContainerScheming?) {
        self.user = user
        super.init(scheme: scheme)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutView() {
        super.layoutView()
        
        filteredUsersMapMixin = FilteredUsersMapMixin(filteredUsersMap: self, user: user, scheme: scheme)
        filteredObservationsMapMixin = FilteredObservationsMapMixin(filteredObservationsMap: self, user: user)
        followUserMapMixin = FollowUserMapMixin(followUser: self, user: user, scheme: scheme)
        mapMixins.append(filteredObservationsMapMixin!)
        mapMixins.append(filteredUsersMapMixin!)
        mapMixins.append(followUserMapMixin!)

        initiateMapMixins()
    }
    
    override func removeFromSuperview() {
        filteredUsersMapMixin = nil
        filteredObservationsMapMixin = nil
        followUserMapMixin = nil
    }
    
}
