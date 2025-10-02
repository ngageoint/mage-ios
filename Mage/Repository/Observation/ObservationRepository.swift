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
    static var currentValue: ObservationRepository = ObservationRepositoryImpl()
}

extension InjectedValues {
    var observationRepository: ObservationRepository {
        get { Self[ObservationRepositoryProviderKey.self] }
        set { Self[ObservationRepositoryProviderKey.self] = newValue }
    }
}

protocol ObservationRepository {
    var refreshPublisher: AnyPublisher<Date, Never>? { get }
    func observeFilteredCount() -> AnyPublisher<Int, Never>?
    func observations(
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<[URIItem], Error>
    func userObservations(
        userUri: URL,
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<[URIItem], Error>
    func observeObservation(observationUri: URL?) -> AnyPublisher<ObservationModel, Never>?
    @available(*, deprecated, message: "Use getObservation to get a model")
    func getObservationNSManagedObject(observationUri: URL?) async -> Observation?
    func getObservation(remoteId: String?) async -> ObservationModel?
    func getObservation(observationUri: URL?) async -> ObservationModel?
    func syncObservation(uri: URL?)
    func fetchObservations() async -> Int
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<ObservationFavoritesModel, Never>?
    func observeChangedRegions() -> AnyPublisher<[MKCoordinateRegion], Never>
    func observationInRegionChanged(region: [MKCoordinateRegion])
}

class ObservationRepositoryImpl: ObservationRepository, ObservableObject {
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
                if let event: EventModel = notification.object as? EventModel {
                    if let eventId = event.remoteId, eventId == Server.currentEventId() {
                        Task { [weak self] in
                            self?.refreshSubject?.send(Date())
                        }
                    }
                }
            }
            .store(in: &cancellable)
    }
    
    func observationInRegionChanged(region: [MKCoordinateRegion]) {
        localDataSource.observationInRegionChanged(region: region)
    }
    
    // Instead of watching the entire list of ObservationLocations and diffing over it
    // just watch the regions that have changed.  This allows the tiles to be redrawn.
    func observeChangedRegions() -> AnyPublisher<[MKCoordinateRegion], Never> {
        localDataSource.observeChangedRegions()
    }
    
    func observeFilteredCount() -> AnyPublisher<Int, Never>? {
        localDataSource.observeFilteredCount()
    }
    
    // this is called when you switch to the Observations Tab
    func observations(
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        localDataSource.observations(paginatedBy: paginator)
    }
    
    // this is called when you switch to the User Tab
    func userObservations(
        userUri: URL,
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        localDataSource.userObservations(
            userUri: userUri,
            paginatedBy: paginator
        )
    }
    
    func observeObservation(observationUri: URL?) -> AnyPublisher<ObservationModel, Never>? {
        localDataSource.observeObservation(observationUri: observationUri)
    }
    
    @available(*, deprecated, message: "Use getObservation to get a model")
    func getObservationNSManagedObject(observationUri: URL?) async -> Observation? {
        await localDataSource.getObservationNSManagedObject(observationUri: observationUri)
    }

    func getObservation(remoteId: String?) async -> ObservationModel? {
        await localDataSource.getObservation(remoteId: remoteId)
    }

    func getObservation(observationUri: URL?) async -> ObservationModel? {
        await localDataSource.getObservation(observationUri: observationUri)
    }
    
    // TODO: implement this
    func syncObservation(uri: URL?) {
        MageLogger.misc.debug("XXX SYNC IT")
    }

    func fetchObservations() async -> Int {
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
