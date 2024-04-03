//
//  ObservationLocalDataSource.swift
//  MAGE
//
//  Created by Daniel Barela on 3/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import Combine
import UIKit
import BackgroundTasks
import MagicalRecord
import NSManagedObjectContextExtensions

protocol ObservationLocalDataSource {
    func getNewestObservation() -> Observation?
    @discardableResult
    func getObservation(remoteId: String?) async -> Observation?
    func getObservation(observationUri: URL?) async -> Observation?
    func getObservationMapItemsInBounds(
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem]
    func getCount(
    ) -> Int
}

class ObservationCoreDataDataSource: ObservationLocalDataSource, ObservableObject {
    func getNewestObservation() -> Observation? {
        return nil
    }

    func getObservation(remoteId: String?) async -> Observation? {
        guard let remoteId = remoteId else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            context.fetchFirst(Observation.self, key: "remoteId", value: remoteId)
        }
    }

    func getObservation(observationUri: URL?) async -> Observation? {
        guard let observationUri = observationUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
                return try? context.existingObject(with: id) as? Observation
            }
            return nil
        }
    }

    func getObservationPredicatesForMap() -> [NSPredicate] {
        var predicates: [NSPredicate] = []
        predicates.append(NSPredicate(format: "observation.eventId == %@", Server.currentEventId() ?? -1))
        if let timePredicate = TimeFilter.getObservationTimePredicate(forField: "observation.timestamp") {
            predicates.append(timePredicate)
        }
        if Observations.getImportantFilter() {
            predicates.append(NSPredicate(format: "observation.observationImportant.important = %@", NSNumber(value: true)))
        }
        if Observations.getFavoritesFilter(),
           let currentUser = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()),
           let remoteId = currentUser.remoteId
        {
            predicates.append(NSPredicate(format: "observation.favorites.favorite CONTAINS %@ AND observation.favorites.userId CONTAINS %@", NSNumber(value: true), remoteId))
        }
        return predicates
    }

    func getObservationMapItemsInBounds(
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem] {
        let context = NSManagedObjectContext.mr_default()

        return await context.perform {
            var predicates: [NSPredicate] = self.getObservationPredicatesForMap()
            if let minLatitude = minLatitude,
               let maxLatitude = maxLatitude,
               let minLongitude = minLongitude,
               let maxLongitude = maxLongitude
            {
                predicates.append(NSPredicate(
                    format: "maxLatitude >= %lf AND minLatitude <= %lf AND maxLongitude >= %lf AND minLongitude <= %lf",
                    minLatitude,
                    maxLatitude,
                    minLongitude,
                    maxLongitude
                ))
            }
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            let fetchRequest = ObservationLocation.fetchRequest()
            fetchRequest.predicate = predicate

            let results = context.fetch(request: fetchRequest)
            return results?.compactMap { location in
                return ObservationMapItem(observation: location)
            } ?? []
        }
    }
    func getCount(
    ) -> Int {
        return 0
    }
}
