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
