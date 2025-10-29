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
    var pushSubject: PassthroughSubject<ObservationFavoriteModel, Never>? { get }
    func handleServerPushResponse(favorite: ObservationFavoriteModel, response: [AnyHashable: Any])
    func getFavoritesToPush() -> [ObservationFavoriteModel]
    func toggleFavorite(observationUri: URL?, userRemoteId: String)
}

class ObservationFavoriteCoreDataDataSource: CoreDataDataSource<ObservationFavorite>, ObservationFavoriteLocalDataSource, ObservableObject {
    
    var pushSubject: PassthroughSubject<ObservationFavoriteModel, Never>? = PassthroughSubject<ObservationFavoriteModel, Never>()
    var favoritesFetchedResultsController: NSFetchedResultsController<ObservationFavorite>?
    
    
    override init() {
        super.init()
        persistence.contextChange
            .sink { [weak self] _ in
                @Injected(\.nsManagedObjectContext)
                var context: NSManagedObjectContext?
                guard let context else { return }
                context.performAndWait { [weak self] in
                    self?.favoritesFetchedResultsController = ObservationFavorite.mr_fetchAllSorted(
                        by: "observation.\(ObservationKey.timestamp.key)",
                        ascending: false,
                        with: NSPredicate(format: "\(ObservationKey.dirty.key) == true"),
                        groupBy: nil,
                        delegate: self,
                        in: context
                    ) as? NSFetchedResultsController<ObservationFavorite>
                }
                for favorite in self?.favoritesFetchedResultsController?.fetchedObjects ?? [] {
                    if favorite.observation?.remoteId != nil {
                        self?.pushSubject?.send(ObservationFavoriteModel(favorite: favorite))
                    }
                }
        }
        .store(in: &cancellables)
        
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context else { return }
        context.performAndWait { [weak self] in
            self?.favoritesFetchedResultsController = ObservationFavorite.mr_fetchAllSorted(
                by: "observation.\(ObservationKey.timestamp.key)",
                ascending: false,
                with: NSPredicate(format: "\(ObservationKey.dirty.key) == true"),
                groupBy: nil,
                delegate: self,
                in: context
            ) as? NSFetchedResultsController<ObservationFavorite>
        }
        for favorite in self.favoritesFetchedResultsController?.fetchedObjects ?? [] {
            if favorite.observation?.remoteId != nil {
                self.pushSubject?.send(ObservationFavoriteModel(favorite: favorite))
            }
        }
    }
    
    func getFavoritesToPush() -> [ObservationFavoriteModel] {
        guard let favorites = self.favoritesFetchedResultsController?.fetchedObjects else { return [] }

        return favorites.compactMap { favorite in
            guard let context = favorite.managedObjectContext else {
                return nil
            }

            let objectID = favorite.objectID
            return context.performAndWait {
                if let refreshedFavorite = context.object(with: objectID) as? ObservationFavorite {
                    return ObservationFavoriteModel(favorite: refreshedFavorite)
                }
                return nil
            }
        }
    }

    
    func observeObservationFavorites(observationUri: URL?) -> AnyPublisher<[ObservationFavoriteModel?], Never>? {
        guard let observationUri = observationUri else {
            return nil
        }
        guard let context = context else { return nil }
        if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri) {
            if let observation = try? context.existingObject(with: id) as? Observation {
                
                var itemChanges: AnyPublisher<[ObservationFavoriteModel?], Never> {
                    let fetchRequest: NSFetchRequest<ObservationFavorite> = ObservationFavorite.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "observation = %@", observation)
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "userId", ascending: false)]
                    return context.listPublisher(for: fetchRequest, transformer: { favorite in
                        ObservationFavoriteModel(favorite: favorite)
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
        guard let context = context else { return }
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
                            let favorite = ObservationFavorite(context: context)
                            observation.addToFavorites(favorite)
                            favorite.observation = observation
                            favorite.dirty = true
                            favorite.favorite = true
                            favorite.userId = userRemoteId
                            try? context.obtainPermanentIDs(for: [favorite])
                        }
                    }
                }
            }
            try? context.save()
        }
    }

    func handleServerPushResponse(favorite: ObservationFavoriteModel, response: [AnyHashable: Any]) {
        MageLogger.misc.debug("Successfuly submitted favorite")
        guard let context = context else { return }
        
        context.performAndWait {
            if let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: favorite.observationFavoriteUri),
               let localFavorite = try? context.existingObject(with: objectId) as? ObservationFavorite
            {
                localFavorite.dirty = false
                if let observation = localFavorite.observation {
                    localFavorite.managedObjectContext?.refresh(observation, mergeChanges: false);
                }
            }
            
        }
    }
}

extension ObservationFavoriteCoreDataDataSource: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let favorite = anObject as? ObservationFavorite {
            switch type {
            case .insert:
                MageLogger.misc.debug("favorite inserted, push em")
                if favorite.observation?.remoteId != nil {
                    MageLogger.misc.debug("sending favorite to push subject")

                    self.pushSubject?.send(ObservationFavoriteModel(favorite: favorite))
                }
            case .delete:
                break
            case .move:
                break
            case .update:
                MageLogger.misc.debug("favorite updated, push em")

                if favorite.observation?.remoteId != nil {
                    self.pushSubject?.send(ObservationFavoriteModel(favorite: favorite))
                }
            @unknown default:
                break
            }
        }
    }
}
