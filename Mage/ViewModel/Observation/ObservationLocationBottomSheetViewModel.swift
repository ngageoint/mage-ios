//
//  ObservationLocationBottomSheetViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

class ObservationLocationBottomSheetViewModel: ObservableObject {
    @Injected(\.observationLocationRepository)
    var repository: ObservationLocationRepository
    
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.observationFavoriteRepository)
    var observationFavoriteRepository: ObservationFavoriteRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    var disposables = Set<AnyCancellable>()
    var observationObserver: AnyCancellable?
    
    var observationLocationUri: URL?
    
    @Published
    var observationMapItem: ObservationMapItem?
    
    lazy var currentUser: UserModel? = {
        userRepository.getCurrentUser()
    }()
    
    var currentUserFavorite: Bool {
        ((observationFavoritesModel?.favoriteUsers?.contains(where: { userId in
            userId == currentUser?.remoteId
        })) == true)
    }
    
    @Published
    var totalFavorites: Int = 0
    
    @Published
    var observationFavoritesModel: ObservationFavoritesModel?
    
    var favoriteCount: Int? {
        observationFavoritesModel?.favoriteUsers?.count
    }
    
    init(observationLocationUri: URL?) {
        self.observationLocationUri = observationLocationUri
        repository.observeObservationLocation(observationLocationUri: observationLocationUri)?
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] updatedObject in
                self?.observationMapItem = updatedObject
            })
            .store(in: &disposables)
        
        $observationMapItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mapItem in
                if let observationObserver = self?.observationObserver {
                    observationObserver.cancel()
                }
                self?.observationObserver = self?.observationRepository.observeObservationFavorites(observationUri: mapItem?.observationId)?
                    .receive(on: DispatchQueue.main)
                    .sink(receiveValue: { [weak self] updatedObject in
                        self?.observationFavoritesModel = updatedObject
                    })
            }
            .store(in: &disposables)

    }
    
    @MainActor
    func setTotalFavorites(count: Int) {
        totalFavorites = count
    }
    
    func toggleFavorite() {
        if let remoteId = currentUser?.remoteId {
            observationFavoriteRepository.toggleFavorite(observationUri: observationMapItem?.observationId, userRemoteId: remoteId)
        }
    }
}
