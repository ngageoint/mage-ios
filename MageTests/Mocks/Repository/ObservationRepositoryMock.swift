//
//  ObservationRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class ObservationRepositoryMock: ObservationRepository {
    var refreshPublisher: AnyPublisher<Date, Never>?
    
    func getObservationNSManagedObject(observationUri: URL?) async -> MAGE.Observation? {
        nil
    }
    
    var syncCalledUri: URL?
    func syncObservation(uri: URL?) {
        syncCalledUri = uri
    }
    
    var observationFavorites: [URL : ObservationFavoritesModel] = [:]
    var favoriteMap: [URL : CurrentValueSubject<ObservationFavoritesModel, Never>] = [:]
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<MAGE.ObservationFavoritesModel, Never>? {
        if let observationUri = observationUri {
            let subject = CurrentValueSubject<ObservationFavoritesModel, Never>(observationFavorites[observationUri] ?? ObservationFavoritesModel(observationId: observationUri))
            favoriteMap[observationUri] = subject
            return AnyPublisher(subject)
        } else {
            return nil
        }
    }
    
    func addFavoriteToObservation(observationUri: URL, userRemoteId: String) {
        let favorite = observationFavorites[observationUri] ?? ObservationFavoritesModel()
        let newFavorite = ObservationFavoritesModel(
            observationId: observationUri,
            favoriteUsers: (favorite.favoriteUsers ?? []) + [userRemoteId]
        )
        observationFavorites[observationUri] = newFavorite
        favoriteMap[observationUri]?.send(newFavorite)
    }
    
    var list: [ObservationModel] = [] {
        willSet {
            filteredCountSubject.send(newValue.count)
        }
    }
    
    var filteredCountSubject: CurrentValueSubject<Int, Never> = CurrentValueSubject(0)
    func observeFilteredCount() -> AnyPublisher<Int, Never>? {
        return AnyPublisher(filteredCountSubject)
    }
    
    func observations(paginatedBy paginator: Trigger.Signal? = nil) -> AnyPublisher<[URIItem], any Error> {
        AnyPublisher(Just(list.compactMap{ model in
            model.observationId
        }.map { userId in
            URIItem.listItem(userId)
        }).setFailureType(to: Error.self))
    }
    
    func userObservations(userUri: URL, paginatedBy paginator: Trigger.Signal? = nil) -> AnyPublisher<[URIItem], any Error> {
        AnyPublisher(Just(list.compactMap{ model in
            if model.userId == userUri {
                return model.observationId
            } else {
                return nil
            }
        }.map { userId in
            URIItem.listItem(userId)
        }).setFailureType(to: Error.self))
    }
    
    var observationSubjectMap: [URL : CurrentValueSubject<ObservationModel, Never>] = [:]
    func observeObservation(observationUri: URL?) -> AnyPublisher<ObservationModel, Never>? {
        if let observation = list.first(where: { model in
            model.observationId == observationUri
        }) {
            let subject = CurrentValueSubject<ObservationModel, Never>(observation)
            observationSubjectMap[observation.observationId!] = subject
            return AnyPublisher(subject)
        } else {
            return nil
        }
    }
    
    func updateObservation(observationUri: URL, model: ObservationModel) {
        list.removeAll { model in
            model.observationId == observationUri
        }
        list.append(model)
        if let subject = observationSubjectMap[observationUri] {
            subject.send(model)
        }
    }
    
    func getObservation(remoteId: String?) async -> ObservationModel? {
        list.first { model in
            model.remoteId == remoteId
        }
    }
    
    func getObservation(observationUri: URL?) async -> ObservationModel? {
        list.first { model in
            model.observationId == observationUri
        }
    }
    
    var fetchObservationsResponseCount = 0
    func fetchObservations() async -> Int {
        fetchObservationsResponseCount
    }
}
