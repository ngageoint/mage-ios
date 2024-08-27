//
//  ObservationImportantLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 8/5/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct ObservationImportantDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationImportantLocalDataSource = ObservationImportantCoreDataDataSource()
}

extension InjectedValues {
    var observationImportantLocalDataSource: ObservationImportantLocalDataSource {
        get { Self[ObservationImportantDataSourceProviderKey.self] }
        set { Self[ObservationImportantDataSourceProviderKey.self] = newValue }
    }
}

protocol ObservationImportantLocalDataSource {
    var pushSubject: PassthroughSubject<ObservationImportantModel, Never>? { get }
    func observeObservationImportant(observationUri: URL?) -> AnyPublisher<[ObservationImportantModel?], Never>?
    func flagImportant(observationUri: URL?, reason: String)
    func removeImportant(observationUri: URL?)
    func handleServerPushResponse(important: ObservationImportantModel, response: [AnyHashable: Any])
    func getImportantsToPush() -> [ObservationImportantModel]
}

class ObservationImportantCoreDataDataSource: CoreDataDataSource<ObservationImportant>, ObservationImportantLocalDataSource, ObservableObject {
    
    var pushSubject: PassthroughSubject<ObservationImportantModel, Never>? = PassthroughSubject<ObservationImportantModel, Never>()
    var importantFetchedResultsController: NSFetchedResultsController<ObservationImportant>?
    
    override init() {
        super.init()
        guard let context = context else { return }
        context.perform { [weak self] in
            self?.importantFetchedResultsController = ObservationImportant.mr_fetchAllSorted(
                by: "observation.\(ObservationKey.timestamp.key)",
                ascending: false,
                with: NSPredicate(format: "\(ObservationKey.dirty.key) == true"),
                groupBy: nil,
                delegate: self,
                in: context
            ) as? NSFetchedResultsController<ObservationImportant>
        }
    }
    
    func getImportantsToPush() -> [ObservationImportantModel] {
        return self.importantFetchedResultsController?.fetchedObjects?.map({ important in
            ObservationImportantModel(observationImportant: important)
        }) ?? []
    }
    
    func observeObservationImportant(observationUri: URL?) -> AnyPublisher<[ObservationImportantModel?], Never>? {
        guard let observationUri = observationUri else {
            return nil
        }
        guard let context = context else { return nil }
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
    
    func flagImportant(observationUri: URL?, reason: String) {
        guard let observationUri = observationUri else {
            return
        }
        guard let context = context else { return }
        
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
        guard let context = context else { return }
        
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
    
    func handleServerPushResponse(important: ObservationImportantModel, response: [AnyHashable: Any]) {
        // verify that the current state in our data is the same as returned from the server
        guard let context = context else { return }
        
        context.performAndWait {
            if let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: important.importantUri),
               let localImportant = try? context.existingObject(with: objectId) as? ObservationImportant
            {
                let serverImportant = response[ObservationKey.important.key] != nil
                if localImportant.important == serverImportant {
                    localImportant.dirty = false
                } else {
                    // force a push again
                    localImportant.timestamp = Date()
                }
                if let observation = localImportant.observation {
                    localImportant.managedObjectContext?.refresh(observation, mergeChanges: false);
                }
            }
        }
    }
}

extension ObservationImportantCoreDataDataSource: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let observationImportant = anObject as? ObservationImportant {
            switch type {
            case .insert:
                NSLog("important inserted, push em")
                if observationImportant.observation?.remoteId != nil {
                    self.pushSubject?.send(ObservationImportantModel(observationImportant: observationImportant))
                }
            case .delete:
                break
            case .move:
                break
            case .update:
                NSLog("important updated, push em")
                if observationImportant.observation?.remoteId != nil {
                    self.pushSubject?.send(ObservationImportantModel(observationImportant: observationImportant))
                }
            @unknown default:
                break
            }
        }
    }
}
