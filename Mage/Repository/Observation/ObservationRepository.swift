//
//  ObservationRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 3/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct ObservationRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationRepository = ObservationRepository()
}

extension InjectedValues {
    var observationRepository: ObservationRepository {
        get { Self[ObservationRepositoryProviderKey.self] }
        set { Self[ObservationRepositoryProviderKey.self] = newValue }
    }
}

class ObservationRepository: ObservableObject {
    @Injected(\.observationLocalDataSource) 
    var localDataSource: ObservationLocalDataSource
    
    @Injected(\.observationRemoteDataSource)
    var remoteDataSource: ObservationRemoteDataSource

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
    @Injected(\.observationLocationLocalDataSource)
    var localDataSource: ObservationLocationLocalDataSource
    
    func getObservationLocation(observationLocationUri: URL?) async -> ObservationLocation? {
        await localDataSource.getObservationLocation(observationLocationUri: observationLocationUri)
    }
}
