//
//  ObservationMapBottomSheet.swift
//  MAGE
//
//  Created by Daniel Barela on 4/6/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import MaterialViews

class ObservationLocationBottomSheetViewModel: ObservableObject {
    @Injected(\.observationLocationRepository)
    var repository: ObservationLocationRepository
    
    @Injected(\.observationRepository)
    var observationRepository: ObservationRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    var disposables = Set<AnyCancellable>()
    var observationObserver: AnyCancellable?
    
    var observationLocationUri: URL?
    
    @Published
    var observationMapItem: ObservationMapItem?
    
    lazy var currentUser: User? = {
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
            .sink(receiveValue: { updatedObject in
                self.observationMapItem = updatedObject
            })
            .store(in: &disposables)
        
        $observationMapItem
            .receive(on: DispatchQueue.main)
            .sink { mapItem in
                if let observationObserver = self.observationObserver {
                    observationObserver.cancel()
                }
                self.observationObserver = self.observationRepository.observeObservationFavorites(observationUri: mapItem?.observationId)?
                    .receive(on: DispatchQueue.main)
                    .sink(receiveValue: { updatedObject in
                        self.observationFavoritesModel = updatedObject
                    })
            }
            .store(in: &disposables)

    }
    
    @MainActor
    func setTotalFavorites(count: Int) {
        totalFavorites = count
    }
    
    func toggleFavorite() {
        observationRepository.toggleFavorite(observationUri: observationMapItem?.observationId)
    }
}

struct ObservationLocationBottomSheet: View {
    @ObservedObject
    var viewModel: ObservationLocationBottomSheetViewModel
    
    var body: some View {
        Group {
            if let observationMapItem = viewModel.observationMapItem {
                VStack(spacing: 0) {
                    if let important = observationMapItem.important {
                        ObservationImportantViewSwiftUI(important: important)
                    }
                    
                    ObservationLocationSummary(
                        timestamp: observationMapItem.timestamp,
                        user: observationMapItem.user,
                        primaryFieldText: observationMapItem.primaryFieldText,
                        secondaryFieldText: observationMapItem.secondaryFieldText,
                        iconPath: observationMapItem.iconPath,
                        error: observationMapItem.error,
                        syncing: observationMapItem.syncing
                    )
                    
                    ObservationLocationBottomSheetActionBar(
                        coordinate: observationMapItem.coordinate,
                        favoriteCount: viewModel.favoriteCount,
                        currentUserFavorite: viewModel.currentUserFavorite,
                        favoriteAction: ObservationActions.favorite(viewModel: viewModel),
                        navigateToAction: CoordinateActions.navigateTo(
                            coordinate: observationMapItem.coordinate,
                            itemKey: observationMapItem.observationLocationId?.absoluteString,
                            dataSource: DataSources.observation
                        )
                    )
                    .padding(4)
                    Button {
                        // let the ripple dissolve before transitioning otherwise it looks weird
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: .ViewObservation, object: observationMapItem.observationId)
                        }
                    } label: {
                        Text("More Details")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MaterialButtonStyle(type: .contained))
                    .padding(8)
                }
                .id(observationMapItem.observationLocationId)
                .ignoresSafeArea()
                
            }
        }
        .animation(.default, value: self.viewModel.observationMapItem != nil)
    }
}
