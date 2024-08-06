//
//  ObservationFavoriteRepository.swift
//  MAGE
//
//  Created by Dan Barela on 8/5/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct ObservationFavoriteRepositoryProviderKey: InjectionKey {
    static var currentValue: ObservationFavoriteRepository = ObservationFavoriteRepository()
}

extension InjectedValues {
    var observationFavoriteRepository: ObservationFavoriteRepository {
        get { Self[ObservationFavoriteRepositoryProviderKey.self] }
        set { Self[ObservationFavoriteRepositoryProviderKey.self] = newValue }
    }
}

class ObservationFavoriteRepository: ObservableObject {
    @Injected(\.observationFavoriteLocalDataSource)
    var localDataSource: ObservationFavoriteLocalDataSource
    
    @Injected(\.observationFavoriteRemoteDataSource)
    var remoteDataSource: ObservationFavoriteRemoteDataSource
    
    var pushingFavorites: [URL : ObservationFavoriteModel] = [:]
    var cancellables: Set<AnyCancellable> = Set()
    
    init() {
        localDataSource.pushSubject?.sink(receiveValue: { favorite in
            Task { [weak self] in
                await self?.pushFavorites(favorites: [favorite])
            }
        })
        .store(in: &cancellables)
    }
    
    func sync() {
        Task { [weak self] in
            await self?.pushFavorites(favorites:self?.localDataSource.getFavoritesToPush())
        }
    }
    
    func toggleFavorite(observationUri: URL?, userRemoteId: String) {
        localDataSource.toggleFavorite(observationUri: observationUri, userRemoteId: userRemoteId)
    }
    
    func pushFavorites(favorites: [ObservationFavoriteModel]?) async {
        guard let favorites = favorites, !favorites.isEmpty else {
            return
        }

        if !DataConnectionUtilities.shouldPushObservations() {
            return
        }
        
        // only push favorites that haven't already been told to be pushed
        var favoritesToPush: [URL : ObservationFavoriteModel] = [:]
        for favorite in favorites {
            if pushingFavorites[favorite.observationFavoriteUri] == nil {
                pushingFavorites[favorite.observationFavoriteUri] = favorite
                favoritesToPush[favorite.observationFavoriteUri] = favorite
            }
        }
        
        NSLog("about to push an additional \(favoritesToPush.count) favorites")
        for favorite in favoritesToPush.values {
            let response = await remoteDataSource.pushFavorite(favorite: favorite)
            localDataSource.handleServerPushResponse(favorite: favorite, response: response)
            self.pushingFavorites.removeValue(forKey: favorite.observationFavoriteUri)
        }
    }
}
