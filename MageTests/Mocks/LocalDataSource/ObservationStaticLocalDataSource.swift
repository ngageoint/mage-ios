//
//  ObservationStaticLocalDataSource.swift
//  MAGETests
//
//  Created by Dan Barela on 8/27/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import BackgroundTasks

@testable import MAGE

final class ObservationStaticLocalDataSource: ObservationLocalDataSource {
    var list: [ObservationModel] = [] {
        willSet {
            filteredCountSubject.send(newValue.count)
        }
    }
    
    var managedObjectList: [Observation] = []
    
    func getLastObservationDate(eventId: Int) -> Date? {
        list.sorted {
            $0.lastModified ?? Date(timeIntervalSince1970: 0) > $1.lastModified ?? Date(timeIntervalSince1970: 0)
        }
        .first?.lastModified
    }
    
    func getLastObservation(eventId: Int) -> MAGE.ObservationModel? {
        list.sorted {
            $0.lastModified ?? Date(timeIntervalSince1970: 0) > $1.lastModified ?? Date(timeIntervalSince1970: 0)
        }
        .first
    }
    
    func getObservation(remoteId: String?) async -> MAGE.ObservationModel? {
        list.first { model in
            model.remoteId == remoteId
        }
    }
    
    func getObservation(observationUri: URL?) async -> MAGE.ObservationModel? {
        list.first { model in
            model.observationId == observationUri
        }
    }
    
    func getObservationNSManagedObject(observationUri: URL?) async -> Observation? {
        return nil
    }
    
    var filteredCountSubject: CurrentValueSubject<Int, Never> = CurrentValueSubject(0)
    func observeFilteredCount() -> AnyPublisher<Int, Never>? {
        return AnyPublisher(filteredCountSubject)
    }
    
    func insert(task: BGTask?, observations: [[AnyHashable : Any]], eventId: Int) async -> Int {
        observations.count
    }
    
    func batchImport(from propertyList: [[AnyHashable : Any]], eventId: Int) async throws -> Int {
        propertyList.count
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
    
    var observationSubjectMap: [URL : CurrentValueSubject<ObservationModel, Never>] = [:]
    func observeObservation(observationUri: URL?) -> AnyPublisher<MAGE.ObservationModel, Never>? {
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
    
    func observations(paginatedBy paginator: MAGE.Trigger.Signal?) -> AnyPublisher<[MAGE.URIItem], any Error> {
        AnyPublisher(Just(list.compactMap{ model in
            model.observationId
        }.map { userId in
            URIItem.listItem(userId)
        }).setFailureType(to: Error.self))
    }
    
    func userObservations(userUri: URL, paginatedBy paginator: MAGE.Trigger.Signal?) -> AnyPublisher<[MAGE.URIItem], any Error> {
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
}
