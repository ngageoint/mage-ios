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

private struct ObservationLocationDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationLocalDataSource = ObservationCoreDataDataSource()
}

extension InjectedValues {
    var observationLocalDataSource: ObservationLocalDataSource {
        get { Self[ObservationLocationDataSourceProviderKey.self] }
        set { Self[ObservationLocationDataSourceProviderKey.self] = newValue }
    }
}

protocol ObservationLocalDataSource {
    func getLastObservationDate(eventId: Int) -> Date?
    func getLastObservation(eventId: Int) -> Observation?
    @discardableResult
    func getObservation(remoteId: String?) async -> Observation?
    func getObservation(observationUri: URL?) async -> Observation?
    func getCount(
    ) -> Int
    func insert(task: BGTask?, observations: [[AnyHashable: Any]], eventId: Int) async -> Int
    func batchImport(from propertyList: [[AnyHashable: Any]], eventId: Int) async throws -> Int
    func toggleFavorite(observationUri: URL?)
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<ObservationFavoritesModel, Never>?
    func observeObservation(observationUri: URL?) -> AnyPublisher<ObservationModel, Never>?
    func observeObservationImportant(observationUri: URL?) -> AnyPublisher<[ObservationImportantModel?], Never>?
    func flagImportant(observationUri: URL?, reason: String)
    func removeImportant(observationUri: URL?)
}

class ObservationCoreDataDataSource: CoreDataDataSource, ObservationLocalDataSource, ObservableObject {
    
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<ObservationFavoritesModel, Never>? {
        guard let observationUri = observationUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
            if let observation = try? context.existingObject(with: id) as? Observation {
                
                var itemChanges: AnyPublisher<ObservationFavoritesModel, Never> {
                    let fetchRequest: NSFetchRequest<ObservationFavorite> = ObservationFavorite.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "observation = %@", observation)
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "userId", ascending: false)]
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
    
    func observeObservationImportant(observationUri: URL?) -> AnyPublisher<[ObservationImportantModel?], Never>? {
        guard let observationUri = observationUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
            if let observation = try? context.existingObject(with: id) as? Observation {
                
                var itemChanges: AnyPublisher<[ObservationImportantModel?], Never> {
                    let fetchRequest: NSFetchRequest<ObservationImportant> = ObservationImportant.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "observation = %@", observation)
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                    return context.listPublisher(for: fetchRequest, transformer: { important in
                        ObservationImportantModel(observationImportant: important)
                    })
                    .catch { _ in Empty() }
                    .eraseToAnyPublisher()
                }
                return itemChanges
            }
        }
        return nil
    }
    
    func toggleFavorite(observationUri: URL?) {
        guard let observationUri = observationUri else { return }
        let context = NSManagedObjectContext.mr_default()
        context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
                if let observation = try? context.existingObject(with: id) as? Observation {
                    observation.toggleFavorite { success, error in
                        observation.managedObjectContext?.refresh(observation, mergeChanges: false)
                    }
                }
            }
        }
    }
    
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
    
    func observeObservation(observationUri: URL?) -> AnyPublisher<ObservationModel, Never>? {
        guard let observationUri = observationUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
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
    
    private func userCanUpdateImportant(observation: Observation, user: User) -> Bool {
        guard let event = observation.event
        else {
            return false
        }
        
        // if the user has update on the event
        if let userRemoteId = user.remoteId,
           let acl = event.acl,
           let userAcl = acl[userRemoteId] as? [String : Any],
           let userPermissions = userAcl[PermissionsKey.permissions.key] as? [String] {
            if (userPermissions.contains(PermissionsKey.update.key)) {
                return true
            }
        }
        
        // if the user has UPDATE_EVENT permission
        if let role = user.role, let rolePermissions = role.permissions {
            if rolePermissions.contains(PermissionsKey.UPDATE_EVENT.key) {
                return true
            }
        }

        return false
    }
    
    func flagImportant(observationUri: URL?, reason: String) {
        guard let observationUri = observationUri else {
            return
        }
        let context = NSManagedObjectContext.mr_default()
        
        return context.performAndWait {
            
            if let currentUser = User.fetchCurrentUser(context: context),
               let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri),
               let observation = try? context.existingObject(with: id) as? Observation,
               userCanUpdateImportant(observation: observation, user: currentUser),
               let userRemoteId = currentUser.remoteId
            {
                if let important = observation.observationImportant {
                    important.dirty = true;
                    important.important = true;
                    important.userId = userRemoteId;
                    important.reason = reason
                    // this will get overridden by the server, but let's set an initial value so the UI has something to display
                    important.timestamp = Date();
                } else {
                    if let important = ObservationImportant.mr_createEntity(in: context) {
                        important.observation = observation
                        observation.observationImportant = important;
                        important.dirty = true;
                        important.important = true;
                        important.userId = userRemoteId;
                        important.reason = reason
                        // this will get overridden by the server, but let's set an initial value so the UI has something to display
                        important.timestamp = Date();
                    }
                }
            }
        }
    }
    
    func removeImportant(observationUri: URL?) {
        guard let observationUri = observationUri else {
            return
        }
        let context = NSManagedObjectContext.mr_default()
        
        return context.performAndWait {
            
            if let currentUser = User.fetchCurrentUser(context: context),
               let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri),
               let observation = try? context.existingObject(with: id) as? Observation,
               userCanUpdateImportant(observation: observation, user: currentUser),
               let userRemoteId = currentUser.remoteId
            {
                if let important = observation.observationImportant {
                    important.dirty = true;
                    important.important = false;
                    important.userId = userRemoteId;
                    important.reason = nil
                    // this will get overridden by the server, but let's set an initial value so the UI has something to display
                    important.timestamp = Date();
                } else {
                    if let important = ObservationImportant.mr_createEntity(in: context) {
                        important.observation = observation
                        observation.observationImportant = important;
                        important.dirty = true;
                        important.important = false;
                        important.userId = userRemoteId;
                        important.reason = nil
                        // this will get overridden by the server, but let's set an initial value so the UI has something to display
                        important.timestamp = Date();
                    }
                }
            }
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
        operation = ObservationDataLoadOperation(observations: observations, eventId: eventId)
        
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
}
