//
//  ObservationFavoritesModel.swift
//  MAGE
//
//  Created by Dan Barela on 7/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct ObservationFavoritesModel: Equatable, Hashable {
    var observationId: URL?
    
    var favoriteUsers: [String]?
}
