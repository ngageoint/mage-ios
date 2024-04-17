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
    func getLastObservationDate(eventId: Int) -> Date?
    func getLastObservation(eventId: Int) -> Observation?
    @discardableResult
    func getObservation(remoteId: String?) async -> Observation?
    func getObservation(observationUri: URL?) async -> Observation?
    func getMapItems(observationUri: URL?) async -> [ObservationMapItem]
    func getMapItems(
        minLatitude: Double?,
        maxLatitude: Double?,
        minLongitude: Double?,
        maxLongitude: Double?
    ) async -> [ObservationMapItem]
    func getCount(
    ) -> Int
    func insert(task: BGTask?, observations: [[AnyHashable: Any]], eventId: Int) async -> Int
    func batchImport(from propertyList: [[AnyHashable: Any]], eventId: Int) async throws -> Int
    func publisher() -> AnyPublisher<CollectionDifference<ObservationLocation>, Never>
}

class ObservationCoreDataDataSource: CoreDataDataSource, ObservationLocalDataSource, ObservableObject {
    func getLastObservationDate(eventId: Int) -> Date? {
        getLastObservation(eventId: eventId)?.lastModified
    }

    func getLastObservation(eventId: Int) -> Observation? {
        let context = NSManagedObjectContext.mr_default()
        return context.performAndWait {
            let user = User.fetchCurrentUser(context: context)
            if let userRemoteId = user?.remoteId {
                let observation = Observation.mr_findFirst(
                    with: NSPredicate(
                        format: "\(ObservationKey.eventId.key) == %i AND user.\(UserKey.remoteId.key) != %@",
                        eventId,
                        userRemoteId
                    ),
                    sortedBy: ObservationKey.lastModified.key,
                    ascending: false,
                    in:context
                )
                return observation
            }
            return nil
        }
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

    func getMapItems(observationUri: URL?) async -> [ObservationMapItem] {
        guard let observationUri = observationUri else {
            return []
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
                if let observation = try? context.existingObject(with: id) as? Observation {
                    return observation.locations?.sorted(by: { one, two in
                        one.order < two.order
                    }).map({ location in
                        ObservationMapItem(observation: location)
                    }) ?? []
                }
            }
            return []
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

    func getCount(
    ) -> Int {
        return 0
    }

    func insert(task: BGTask?, observations: [[AnyHashable: Any]], eventId: Int) async -> Int {
        let count = observations.count
        NSLog("Received \(count) \(DataSources.observation.key) records.")

        // Create an operation that performs the main part of the background task.
        operation = ObservationDataLoadOperation(observations: observations, localDataSource: self, eventId: eventId)
        
        return await executeOperationInBackground(task: task)
    }

    func batchImport(from propertyList: [[AnyHashable: Any]], eventId: Int) async throws -> Int {
        let initial = true
        let saveStart = Date()
        NSLog("TIMING Saving Observations for event \(eventId) @ \(saveStart)")
        let rootSavingContext = NSManagedObjectContext.mr_rootSaving();
        let localContext = NSManagedObjectContext.mr_context(withParent: rootSavingContext);
        return await localContext.perform {
            NSLog("TIMING There are \(propertyList.count) features to save, chunking into groups of 250")
            localContext.mr_setWorkingName(#function)

            var chunks = propertyList.chunked(into: 250);
            var newObservationCount = 0;
            var observationToNotifyAbout: Observation?;
            var eventFormDictionary: [NSNumber: [[String: AnyHashable]]] = [:]
            if let event = Event.getEvent(eventId: eventId as NSNumber, context: localContext), let eventForms = event.forms {
                for eventForm in eventForms {
                    if let formId = eventForm.formId, let json = eventForm.json?.json {
                        eventFormDictionary[formId] = json[FormKey.fields.key] as? [[String: AnyHashable]]
                    }
                }
            }
            localContext.reset();
            NSLog("TIMING we have \(chunks.count) groups to save")
            while (chunks.count > 0) {
                autoreleasepool {
                    guard let features = chunks.last else {
                        return;
                    }
                    chunks.removeLast();
                    let createObservationsDate = Date()
                    NSLog("TIMING creating \(features.count) observations for chunk \(chunks.count)")

                    for observation in features {
                        if let newObservation = Observation.create(feature: observation, eventForms: eventFormDictionary, context: localContext) {
                            newObservationCount = newObservationCount + 1;
                            if (!initial) {
                                observationToNotifyAbout = newObservation;
                            }
                        }
                    }
                    NSLog("TIMING created \(features.count) observations for chunk \(chunks.count) Elapsed: \(createObservationsDate.timeIntervalSinceNow) seconds")
                }

                // only save once per chunk
                let localSaveDate = Date()
                do {
                    NSLog("TIMING saving \(propertyList.count) observations on local context")
                    try localContext.save()
                } catch {
                    print("Error saving observations: \(error)")
                }
                NSLog("TIMING saved \(propertyList.count) observations on local context. Elapsed \(localSaveDate.timeIntervalSinceNow) seconds")

                rootSavingContext.perform {
                    let rootSaveDate = Date()

                    do {
                        NSLog("TIMING saving \(propertyList.count) observations on root context")
                        try rootSavingContext.save()
                    } catch {
                        print("Error saving observations: \(error)")
                    }
                    NSLog("TIMING saved \(propertyList.count) observations on root context. Elapsed \(rootSaveDate.timeIntervalSinceNow) seconds")

                }

                localContext.reset();
                NSLog("TIMING reset the local context for chunk \(chunks.count)")
                NSLog("Saved chunk \(chunks.count)")
            }

            NSLog("Received \(newObservationCount) new observations and send bulk is \(initial)")
            if ((initial && newObservationCount > 0) || newObservationCount > 1) {
                NotificationRequester.sendBulkNotificationCount(UInt(newObservationCount), in: Event.getCurrentEvent(context: localContext));
            } else if let observationToNotifyAbout = observationToNotifyAbout {
                NotificationRequester.observationPulled(observationToNotifyAbout);
            }

            NSLog("TIMING Saved Observations for event \(eventId). Elapsed: \(saveStart.timeIntervalSinceNow) seconds")
            return newObservationCount
        }
    }

    func publisher() -> AnyPublisher<CollectionDifference<ObservationLocation>, Never> {
        let context = NSManagedObjectContext.mr_default()

        var itemChanges: AnyPublisher<CollectionDifference<ObservationLocation>, Never> {
            let fetchRequest: NSFetchRequest<ObservationLocation> = ObservationLocation.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "eventId", ascending: false)]
            return context.changesPublisher(for: fetchRequest, transformer: { location in
                location
            })
            .catch { _ in Empty() }
            .eraseToAnyPublisher()
        }

        return itemChanges
    }
}
