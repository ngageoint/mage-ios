//
//  ObservationMapItemRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 4/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationMapItemRepository: ObservableObject {

    let localDataSource: ObservationLocationLocalDataSource

    init(localDataSource: ObservationLocationLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func getMapItems(observationUri: URL?) async -> [ObservationMapItem] {
        return await localDataSource.getMapItems(
            observationUri: observationUri,
            minLatitude: nil,
            maxLatitude: nil,
            minLongitude: nil,
            maxLongitude: nil
        )
    }
}
