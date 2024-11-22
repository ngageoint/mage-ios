//
//  ObservationFavoriteRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class ObservationFavoriteRepositoryMock: ObservationFavoriteRepository {
    
    func toggleFavorite(observationUri: URL?, userRemoteId: String) {
        
    }
    
    func pushFavorites(favorites: [MAGE.ObservationFavoriteModel]?) async {
        
    }
    
    var syncCalled = false
    func sync() {
        syncCalled = true
    }
    
}
