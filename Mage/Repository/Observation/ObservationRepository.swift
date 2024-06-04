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
    let remoteDataSource: ObservationRemoteDataSource

    init(localDataSource: ObservationLocalDataSource, remoteDataSource: ObservationRemoteDataSource) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
    }

    func getObservation(remoteId: String?) async -> Observation? {
        await localDataSource.getObservation(remoteId: remoteId)
    }

    func getObservation(observationUri: URL?) async -> Observation? {
        await localDataSource.getObservation(observationUri: observationUri)
    }

    func fetchObservations() async -> Int {
        NSLog("Fetching Observations")

        guard let eventId = Server.currentEventId() else {
            return 0
        }

        let newestObservationDate = localDataSource.getLastObservationDate(eventId: eventId.intValue)
        let observationJson = await remoteDataSource.fetch(eventId: eventId.intValue, date: newestObservationDate)
        let inserted = await localDataSource.insert(task: nil, observations: observationJson, eventId: eventId.intValue)

        return inserted
    }
}

class ObservationLocationRepository: ObservableObject {
    let localDataSource: ObservationLocationLocalDataSource
    
    init(localDataSource: ObservationLocationLocalDataSource) {
        self.localDataSource = localDataSource
    }
    
    func getObservationLocation(observationLocationUri: URL?) async -> ObservationLocation? {
        await localDataSource.getObservationLocation(observationLocationUri: observationLocationUri)
    }
}
