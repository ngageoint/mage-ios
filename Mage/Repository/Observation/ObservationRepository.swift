//
//  ObservationRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 3/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationRepository: ObservableObject {
    let localDataSource: ObservationLocalDataSource

    init(localDataSource: ObservationLocalDataSource) {
        self.localDataSource = localDataSource
    }

    func getObservation(remoteId: String?) async -> Observation? {
        await localDataSource.getObservation(remoteId: remoteId)
    }

    func getObservation(observationUri: URL?) async -> Observation? {
        await localDataSource.getObservation(observationUri: observationUri)
    }

    func getMapItems(observationUri: URL?) async -> [ObservationMapItem] {
        await localDataSource.getMapItems(observationUri: observationUri)
    }

    func getMapItems(
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem] {
        await localDataSource.getMapItems(
            minLatitude: minLatitude,
            maxLatitude: maxLatitude,
            minLongitude: minLongitude,
            maxLongitude: maxLongitude
        )
    }
}
