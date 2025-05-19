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
import NSManagedObjectContextExtensions

private struct ObservationLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationLocalDataSource = ObservationCoreDataDataSource()
}

extension InjectedValues {
    var observationLocalDataSource: ObservationLocalDataSource {
        get { Self[ObservationLocalDataSourceProviderKey.self] }
        set { Self[ObservationLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol ObservationLocalDataSource {
    func getLastObservationDate(eventId: Int) -> Date?
    func getLastObservation(eventId: Int) -> ObservationModel?
    func getObservationNSManagedObject(observationUri: URL?) async -> Observation?
    @discardableResult
    func getObservation(remoteId: String?) async -> ObservationModel?
    func getObservation(observationUri: URL?) async -> ObservationModel?
    func observeFilteredCount() -> AnyPublisher<Int, Never>?
    func insert(task: BGTask?, observations: [[AnyHashable: Any]], eventId: Int) async -> Int
    func batchImport(from propertyList: [[AnyHashable: Any]], eventId: Int) async throws -> Int
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<ObservationFavoritesModel, Never>?
    func observeObservation(observationUri: URL?) -> AnyPublisher<ObservationModel, Never>?
    func observations(
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<[URIItem], Error>
    func userObservations(
        userUri: URL,
        paginatedBy paginator: Trigger.Signal?
    ) -> AnyPublisher<[URIItem], Error>
}

struct ObservationModelPage {
    var observationList: [ObservationItem]
    var next: Int?
    var currentHeader: String?
}

class ObservationCoreDataDataSource: CoreDataDataSource<Observation>, ObservationLocalDataSource, ObservableObject {
    private enum FilterKeys: String {
        case userId
    }
    
    func userObservations(
        userUri: URL,
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        uris(
            parameters: [FilterKeys.userId: userUri],
            at: nil,
            currentHeader: nil,
            paginatedBy: paginator
        )
        .map(\.list)
        .eraseToAnyPublisher()
    }
    
    func observations(
        paginatedBy paginator: Trigger.Signal? = nil
    ) -> AnyPublisher<[URIItem], Error> {
        return uris(
            at: nil,
            currentHeader: nil,
            paginatedBy: paginator
        )
        .map(\.list)
        .eraseToAnyPublisher()
    }
    
    override func getFetchRequest(parameters: [AnyHashable: Any]? = nil) -> NSFetchRequest<Observation> {
        let request = Observation.fetchRequest()
        let predicates: [NSPredicate] = {
            if let userUri = parameters?[FilterKeys.userId] as? URL {
                if let id = context?.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri),
                   let user = try? context?.existingObject(with: id) as? User
                {
                    return [
                        NSPredicate(
                            format: "%K == %@ AND %K == %@",
                            argumentArray: [
                                #keyPath(Observation.user),
                                user,
                                #keyPath(Observation.eventId),
                                Server.currentEventId() ?? -1]
                        )
                    ]
                }
            } else {
                return Observations.getPredicatesForObservations(context) as? [NSPredicate] ?? []
            }
            return []
        }()
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.predicate = predicate
        MageLogger.misc.debug("Predicate \(predicate.debugDescription)")

        request.includesSubentities = false
        request.propertiesToFetch = ["timestamp", "user"]
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.includesPendingChanges = true
        return request
    }
    
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<ObservationFavoritesModel, Never>? {
        guard let observationUri = observationUri else {
            return nil
        }
        guard let context = context else { return nil }
        if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
            if let observation = try? context.existingObject(with: id) as? Observation {
                
                var itemChanges: AnyPublisher<ObservationFavoritesModel, Never> {
                    let fetchRequest: NSFetchRequest<ObservationFavorite> = ObservationFavorite.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(ObservationFavorite.observation), observation)
                    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ObservationFavorite.userId, ascending: false)]
                    return context.listPublisher(for: fetchRequest, transformer: { favorite in
                        favorite.favorite ? favorite.userId : nil
                    })
                    .map({ userIds in
                        return ObservationFavoritesModel(
                            observationId: observationUri,
                            favoriteUsers: userIds.compactMap { $0 }
                        )
                    })
                    .catch { _ in Empty() }
                    .eraseToAnyPublisher()
                }
                return itemChanges
            }
        }
        return nil
    }
    
    func getLastObservationDate(eventId: Int) -> Date? {
        getLastObservation(eventId: eventId)?.lastModified
    }

    func getLastObservation(eventId: Int) -> ObservationModel? {
        guard let context = context else { return nil }
        return context.performAndWait {
            let user = User.fetchCurrentUser(context: context)
            if let userRemoteId = user?.remoteId {
                return try? context.fetchFirst(
                    Observation.self,
                    sortBy: [NSSortDescriptor(keyPath: \Observation.lastModified, ascending: false)],
                    predicate: NSPredicate(
                        format: "%K == %i AND %K != %@",
                        #keyPath(Observation.eventId),
                        eventId,
                        #keyPath(Observation.user.remoteId),
                        userRemoteId
                    )
                ).map({ observation in
                    ObservationModel(observation: observation)
                })
            }
            return nil
        }
    }

    func getObservation(remoteId: String?) async -> ObservationModel? {
        guard let remoteId = remoteId else {
            return nil
        }
        guard let context = context else { return nil }
        return await context.perform {
            context.fetchFirst(Observation.self, key: "remoteId", value: remoteId)
                .map { observation in
                    ObservationModel(observation: observation)
                }
        }
    }

    func getObservation(observationUri: URL?) async -> ObservationModel? {
        await getObservationNSManagedObject(observationUri: observationUri).map { observation in
            ObservationModel(observation: observation)
        }
    }
    
    func getObservationNSManagedObject(observationUri: URL?) async -> Observation? {
        guard let observationUri = observationUri else {
            return nil
        }
        guard let context = context else { return nil }
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
                return try? context.existingObject(with: id) as? Observation
            }
            return nil
        }
    }
    
    func observeObservation(observationUri: URL?) -> AnyPublisher<ObservationModel, Never>? {
        guard let observationUri = observationUri else {
            return nil
        }
        guard let context = context else { return nil }
        return context.performAndWait {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
                if let observation = try? context.existingObject(with: id) as? Observation {
                    return publisher(for: observation, in: context)
                        .prepend(observation)
                        .map({ observation in
                            return ObservationModel(observation: observation)
                        })
                        .eraseToAnyPublisher()
                }
            }
            return nil
        }
    }
    
    func observeFilteredCount() -> AnyPublisher<Int, Never>? {
        guard let context = context else { return nil }
        var itemChanges: AnyPublisher<Int, Never> {
            
            let request = Observation.fetchRequest()
            let predicates: [NSPredicate] = Observations.getPredicatesForObservations(context) as? [NSPredicate] ?? []
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.predicate = predicate
            request.includesSubentities = false
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            return context.listPublisher(for: request, transformer: { $0 })
            .catch { _ in Empty() }
            .map({ output in
                output.count
            })
            .eraseToAnyPublisher()
        }
        return itemChanges
    }

    func insert(task: BGTask?, observations: [[AnyHashable: Any]], eventId: Int) async -> Int {
        let count = observations.count
        MageLogger.misc.debug("Received \(count) \(DataSources.observation.key) records.")

        // Create an operation that performs the main part of the background task.
        operation = ObservationDataLoadOperation(observations: observations, eventId: eventId)
        
        return await executeOperationInBackground(task: task)
    }

    func batchImport(from propertyList: [[AnyHashable: Any]], eventId: Int) async throws -> Int {
        let initial = true
        let saveStart = Date()
        MageLogger.misc.debug("TIMING Saving Observations for event \(eventId) @ \(saveStart)")
        
        let backgroundContext = persistence.getNewBackgroundContext(name: #function)
        
        return await backgroundContext.perform {
            MageLogger.misc.debug("TIMING There are \(propertyList.count) features to save, chunking into groups of 250")

            var chunks = propertyList.chunked(into: 250);
            var newObservationCount = 0;
            var observationToNotifyAbout: Observation?;
            var eventFormDictionary: [NSNumber: [[String: AnyHashable]]] = [:]
            if let event = Event.getEvent(eventId: eventId as NSNumber, context: backgroundContext), let eventForms = event.forms {
                for eventForm in eventForms {
                    if let formId = eventForm.formId, let json = eventForm.json?.json {
                        eventFormDictionary[formId] = json[FormKey.fields.key] as? [[String: AnyHashable]]
                    }
                }
            }
            backgroundContext.reset();
            MageLogger.misc.debug("TIMING we have \(chunks.count) groups to save")
            while (chunks.count > 0) {
                autoreleasepool {
                    guard let features = chunks.last else {
                        return;
                    }
                    chunks.removeLast();
                    let createObservationsDate = Date()
                    MageLogger.misc.debug("TIMING creating \(features.count) observations for chunk \(chunks.count)")

                    for observation in features {
                        if let newObservation = Observation.create(feature: observation, eventForms: eventFormDictionary, context: backgroundContext) {
                            newObservationCount = newObservationCount + 1;
                            if (!initial) {
                                observationToNotifyAbout = newObservation;
                            }
                        }
                    }
                    MageLogger.misc.debug("TIMING created \(features.count) observations for chunk \(chunks.count) Elapsed: \(createObservationsDate.timeIntervalSinceNow) seconds")
                }

                // only save once per chunk
                let localSaveDate = Date()
                do {
                    MageLogger.misc.debug("TIMING saving \(propertyList.count) observations on local context")
                    try backgroundContext.save()
                } catch {
                    MageLogger.misc.error("Error saving observations: \(error)")
                }
                MageLogger.misc.debug("TIMING saved \(propertyList.count) observations on local context. Elapsed \(localSaveDate.timeIntervalSinceNow) seconds")

                let rootContext = self.persistence.getRootContext()
                rootContext.perform {
                    let rootSaveDate = Date()

                    do {
                        MageLogger.misc.debug("TIMING saving \(propertyList.count) observations on root context")
                        try rootContext.save()
                    } catch {
                        MageLogger.misc.error("Error saving observations: \(error)")
                    }
                    MageLogger.misc.debug("TIMING saved \(propertyList.count) observations on root context. Elapsed \(rootSaveDate.timeIntervalSinceNow) seconds")

                }

                backgroundContext.reset();
                MageLogger.misc.debug("TIMING reset the local context for chunk \(chunks.count)")
                MageLogger.misc.debug("Saved chunk \(chunks.count)")
            }

            MageLogger.misc.debug("Received \(newObservationCount) new observations and send bulk is \(initial)")
            if ((initial && newObservationCount > 0) || newObservationCount > 1) {
                NotificationRequester.sendBulkNotificationCount(UInt(newObservationCount), in: Event.getCurrentEvent(context: backgroundContext));
            } else if let observationToNotifyAbout = observationToNotifyAbout {
                NotificationRequester.observationPulled(observationToNotifyAbout);
            }

            MageLogger.misc.debug("TIMING Saved Observations for event \(eventId). Elapsed: \(saveStart.timeIntervalSinceNow) seconds")
            return newObservationCount
        }
    }
}
