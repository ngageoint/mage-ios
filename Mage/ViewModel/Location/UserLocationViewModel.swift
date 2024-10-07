//
//  UserLocationViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class UserLocationViewModel: ObservableObject {
    @Injected(\.locationRepository)
    var locationRepository: LocationRepository
    
    init(uri: URL) {
        
    }
}
