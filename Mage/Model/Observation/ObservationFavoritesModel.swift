//
//  ObservationFavoritesModel.swift
//  MAGE
//
//  Created by Dan Barela on 7/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct ObservationFavoriteModel: Equatable, Hashable {
    var observationUri: URL?
    var observationFavoriteUri: URL
    var observationRemoteId: String?
    var favorite: Bool
    var userId: String?
    var eventId: NSNumber?
}

extension ObservationFavoriteModel {
    init(favorite: ObservationFavorite) {
        self.observationUri = favorite.observation?.objectID.uriRepresentation()
        self.observationFavoriteUri = favorite.objectID.uriRepresentation()
        self.observationRemoteId = favorite.observation?.remoteId
        self.favorite = favorite.favorite
        self.userId = favorite.userId
        self.eventId = favorite.observation?.eventId
    }
}

struct ObservationFavoritesModel: Equatable, Hashable {
    var observationId: URL?
    
    var favoriteUsers: [String]?
}
