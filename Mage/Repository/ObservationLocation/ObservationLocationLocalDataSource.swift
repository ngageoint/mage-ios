//
//  ObservationLocationLocalDataSource.swift
//  MAGE
//
//  Created by Daniel Barela on 4/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct ObservationLocationLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationLocationLocalDataSource = ObservationLocationCoreDataDataSource()
}

extension InjectedValues {
    var observationLocationLocalDataSource: ObservationLocationLocalDataSource {
        get { Self[ObservationLocationLocalDataSourceProviderKey.self] }
        set { Self[ObservationLocationLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol ObservationLocationLocalDataSource {
    func getObservationLocation(observationLocationUri: URL?) async -> ObservationLocation?
    func getMapItems(
        observationLocationUri: URL?,
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem]
    func getMapItems(
        observationUri: URL?,
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem]
    func getMapItems(
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem]
    func locationsPublisher() -> AnyPublisher<CollectionDifference<ObservationMapItem>, Never>
    func observeObservationLocation(
        observationLocationUri: URL?
    ) -> AnyPublisher<ObservationMapItem, Never>?
}

class ObservationLocationCoreDataDataSource: CoreDataDataSource, ObservationLocationLocalDataSource {
    
    func observeObservationLocation(observationLocationUri: URL?) -> AnyPublisher<ObservationMapItem, Never>? {
        guard let observationLocationUri = observationLocationUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        return context.performAndWait {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationLocationUri) {
                if let observationLocation = try? context.existingObject(with: id) as? ObservationLocation {
                    return publisher(for: observationLocation, in: context)
                        .prepend(observationLocation)
                        .map({ observationLocation in
                            return ObservationMapItem(observation: observationLocation)
                        })
                        .eraseToAnyPublisher()
                }
            }
            return nil
        }
    }
    
    func getObservationLocation(observationLocationUri: URL?) async -> ObservationLocation? {
        guard let observationLocationUri = observationLocationUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationLocationUri) {
                return try? context.existingObject(with: id) as? ObservationLocation
            }
            return nil
        }
    }

    func getObservationPredicates() -> [NSPredicate] {
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
    
    func getMapItems(
        observationLocationUri: URL?,
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem] {
        guard let observationLocationUri = observationLocationUri else {
            return []
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            var predicates: [NSPredicate] = []
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
            
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationLocationUri) {
                predicates.append(NSPredicate(
                    format: "self == %@",
                    id
                ))
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                let fetchRequest = ObservationLocation.fetchRequest()
                fetchRequest.predicate = predicate

                let results = context.fetch(request: fetchRequest)
                return results?.compactMap { location in
//                if let location = try? context.existingObject(with: id) as? ObservationLocation {
                    return ObservationMapItem(observation: location)
                } ?? []
            }
            return []
        }
    }

    func getMapItems(
        observationUri: URL?,
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem] {
        guard let observationUri = observationUri else {
            return []
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {

            var predicates: [NSPredicate] = []
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
            
            return results?.sorted(by: { one, two in
                one.order < two.order
            }).filter({ location in
                location.observation?.objectID.uriRepresentation() == observationUri
            })
            .map({ location in
                ObservationMapItem(observation: location)
            }) ?? []
        }
    }

    func getMapItems(
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem] {
        let context = NSManagedObjectContext.mr_default()

        return await context.perform {
            var predicates: [NSPredicate] = self.getObservationPredicates()
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

    func locationsPublisher() -> AnyPublisher<CollectionDifference<ObservationMapItem>, Never> {
        let context = NSManagedObjectContext.mr_default()

        var itemChanges: AnyPublisher<CollectionDifference<ObservationMapItem>, Never> {
            let fetchRequest: NSFetchRequest<ObservationLocation> = ObservationLocation.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "eventId", ascending: false)]
            return context.changesPublisher(for: fetchRequest, transformer: { location in
                ObservationMapItem(observation: location)
            })
            .catch { _ in Empty() }
            .eraseToAnyPublisher()
        }

        return itemChanges
    }
}
