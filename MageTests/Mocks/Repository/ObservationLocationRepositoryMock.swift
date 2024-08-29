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
    
    func getObservationLocation(observationLocationUri: URL?) async -> ObservationMapItem? {
        list.first { item in
            item.observationLocationId == observationLocationUri
        }
    }
    
    func observeObservationLocation(observationLocationUri: URL?) -> AnyPublisher<ObservationMapItem, Never>? {
        AnyPublisher(Just(list[0]))
    }
    
    func getObservationMapItems(observationUri: URL, formId: String, fieldName: String) async -> [ObservationMapItem]? {
        list
    }
}
