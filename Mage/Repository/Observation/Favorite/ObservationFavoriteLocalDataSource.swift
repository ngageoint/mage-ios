//
//  ObservationFavoriteLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 8/6/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct ObservationFavoriteDataSourceProviderKey: InjectionKey {
    static var currentValue: ObservationFavoriteLocalDataSource = ObservationFavoriteCoreDataDataSource()
}

extension InjectedValues {
    var observationFavoriteLocalDataSource: ObservationFavoriteLocalDataSource {
        get { Self[ObservationFavoriteDataSourceProviderKey.self] }
        set { Self[ObservationFavoriteDataSourceProviderKey.self] = newValue }
    }
}

protocol ObservationFavoriteLocalDataSource {
    var pushSubject: PassthroughSubject<ObservationFavorite, Never>? { get }
    func handleServerPushResponse(favorite: ObservationFavorite, response: [AnyHashable: Any])
    func getFavoritesToPush() -> [ObservationFavorite]
    func toggleFavorite(observationUri: URL?, userRemoteId: String)
}

class ObservationFavoriteCoreDataDataSource: CoreDataDataSource, ObservationFavoriteLocalDataSource, ObservableObject {
    
    var pushSubject: PassthroughSubject<ObservationFavorite, Never>? = PassthroughSubject<ObservationFavorite, Never>()
    var favoritesFetchedResultsController: NSFetchedResultsController<ObservationFavorite>?
    
    override init() {
        super.init()
        let context = NSManagedObjectContext.mr_default();
        context.perform { [weak self] in
            self?.favoritesFetchedResultsController = ObservationFavorite.mr_fetchAllSorted(
                by: "observation.\(ObservationKey.timestamp.key)",
                ascending: false,
                with: NSPredicate(format: "\(ObservationKey.dirty.key) == true"),
                groupBy: nil,
                delegate: self,
                in: context
            ) as? NSFetchedResultsController<ObservationFavorite>
        }
    }
    
    func getFavoritesToPush() -> [ObservationFavorite] {
        return self.favoritesFetchedResultsController?.fetchedObjects?.map({ favorite in
            favorite
        }) ?? []
    }
    
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<[ObservationFavorite?], Never>? {
        guard let observationUri = observationUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
            if let observation = try? context.existingObject(with: id) as? Observation {
                
                var itemChanges: AnyPublisher<[ObservationFavorite?], Never> {
                    let fetchRequest: NSFetchRequest<ObservationFavorite> = ObservationFavorite.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "observation = %@", observation)
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "userId", ascending: false)]
                    return context.listPublisher(for: fetchRequest, transformer: { favorite in
                        favorite
                    })
                    .catch { _ in Empty() }
                    .eraseToAnyPublisher()
                }
                return itemChanges
            }
        }
        return nil
    }
    
    func toggleFavorite(observationUri: URL?, userRemoteId: String) {
        guard let observationUri = observationUri else { return }
        let context = NSManagedObjectContext.mr_default()
        context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
                if let observation = try? context.existingObject(with: id) as? Observation {
                    if let favorite = observation.favoritesMap[userRemoteId], favorite.favorite {
                        // toggle off
                        favorite.dirty = true
                        favorite.favorite = false
                    } else {
                        // toggle on
                        if let favorite = observation.favoritesMap[userRemoteId] {
                            favorite.dirty = true
                            favorite.favorite = true
                            favorite.userId = userRemoteId
                        } else {
                            if let favorite = ObservationFavorite.mr_createEntity(in: context) {
                                observation.addToFavorites(favorite)
                                favorite.observation = observation
                                favorite.dirty = true
                                favorite.favorite = true
                                favorite.userId = userRemoteId
                            }
                        }
                    }
                }
            }
        }
    }

    func handleServerPushResponse(favorite: ObservationFavorite, response: [AnyHashable: Any]) {
        NSLog("Successfuly submitted favorite")
        let context = NSManagedObjectContext.mr_default()
        
        context.performAndWait {
            let localFavorite = favorite.mr_(in: context)
            localFavorite?.dirty = false
        }
    }
}

extension ObservationFavoriteCoreDataDataSource: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let observationFavorite = anObject as? ObservationFavorite {
            switch type {
            case .insert:
                NSLog("important inserted, push em")
                if observationFavorite.observation?.remoteId != nil {
                    self.pushSubject?.send(observationFavorite)
                }
            case .delete:
                break
            case .move:
                break
            case .update:
                NSLog("important updated, push em")
                if observationFavorite.observation?.remoteId != nil {
                    self.pushSubject?.send(observationFavorite)
                }
            @unknown default:
                break
            }
        }
    }
}
