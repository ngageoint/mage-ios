//
//  ObservationLocationRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class ObservationLocationRepositoryMock: ObservationLocationRepository {
    
    var list: [ObservationMapItem] = []
    
    override func getObservationLocation(observationLocationUri: URL?) async -> ObservationMapItem? {
        list.first { item in
            item.observationLocationId == observationLocationUri
        }
    }
    
    override func observeObservationLocation(observationLocationUri: URL?) -> AnyPublisher<ObservationMapItem, Never>? {
        AnyPublisher(Just(list[0]))
    }
    
    override func getObservationMapItems(observationUri: URL, formId: String, fieldName: String) async -> [ObservationMapItem]? {
        list
    }
}
