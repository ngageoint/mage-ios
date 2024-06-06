//
//  BottomSheetRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/6/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class BottomSheetRepository: ObservableObject {
    @Injected(\.observationLocationRepository)
    var observationLocationRepository: ObservationLocationRepository
    
}
