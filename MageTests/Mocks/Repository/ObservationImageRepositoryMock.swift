//
//  ObservationImageRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class ObservationImageRepositoryMock: ObservationImageRepository {
    func clearCache() {
        
    }
    
    func imageName(eventId: Int64?, formId: Int?, primaryFieldText: String?, secondaryFieldText: String?) -> String? {
        "defaultMarker"
    }
    
    func imageName(observation: MAGE.Observation?) -> String? {
        "defaultMarker"
    }
    
    func imageAtPath(imagePath: String?) -> UIImage {
        UIImage(named: "defaultMarker")!
    }
    
    func image(observation: MAGE.Observation) -> UIImage {
        UIImage(named: "defaultMarker")!
    }
    
    
}
