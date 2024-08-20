//
//  ObservationRepository.swift
//  MAGE
//
//  Created by Daniel Barela on 3/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

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
    
    var refreshPublisher: AnyPublisher<Date, Never>? {
        refreshSubject?.eraseToAnyPublisher()
    }
    
    var cancellable = Set<AnyCancellable>()

    var refreshSubject: PassthroughSubject<Date, Never>? = PassthroughSubject<Date, Never>()
    
    init() {
        UserDefaults.standard.publisher(for: \.observationTimeFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(DataSources.observation.key): \(order)")
                Task { [weak self] in
                    self?.refreshSubject?.send(Date())
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterUnitKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(DataSources.observation.key): \(order)")
                Task { [weak self] in
                    self?.refreshSubject?.send(Date())
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.observationTimeFilterNumberKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(DataSources.observation.key): \(order)")
                Task { [weak self] in
                    self?.refreshSubject?.send(Date())
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.importantFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                NSLog("Order update \(DataSources.observation.key): \(order)")
                Task { [weak self] in
                    self?.refreshSubject?.send(Date())
                }
            }
            .store(in: &cancellable)
        UserDefaults.standard.publisher(for: \.favoritesFilterKey)
            .removeDuplicates()
            .sink { [weak self] order in
                Task { [weak self] in
                    self?.refreshSubject?.send(Date())
                }
            }
            .store(in: &cancellable)

        NotificationCenter.default.publisher(for: .MAGEFormFetched)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let event: Event = notification.object as? Event {
                    if let eventId = event.remoteId, eventId == Server.currentEventId() {
                        Task { [weak self] in
                            self?.refreshSubject?.send(Date())
                        }
                    }
                }
            }
            .store(in: &cancellable)
    }
    
    func observeFilteredCount() -> AnyPublisher<Int, Never>? {
        localDataSource.observeFilteredCount()
    }
    
    func observations(
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[ObservationItem], Error> {
        localDataSource.observations(paginatedBy: paginator)
    }
    
    func userObservations(
        userUri: URL,
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[ObservationItem], Error> {
        localDataSource.userObservations(
            userUri: userUri,
            paginatedBy: paginator
        )
    }
    
    func observeObservation(observationUri: URL?) -> AnyPublisher<ObservationModel, Never>? {
        localDataSource.observeObservation(observationUri: observationUri)
    }

    func getObservation(remoteId: String?) async -> Observation? {
        await localDataSource.getObservation(remoteId: remoteId)
    }

    func getObservation(observationUri: URL?) async -> Observation? {
        await localDataSource.getObservation(observationUri: observationUri)
    }
    
    func syncObservation(uri: URL?) {
        print("XXX SYNC IT")
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
    
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<ObservationFavoritesModel, Never>? {
        localDataSource.observeObservationFavorites(observationUri: observationUri)
    }
}
