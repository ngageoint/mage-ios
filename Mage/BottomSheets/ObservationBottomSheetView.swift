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
                    .padding(16)
                    
                    ObservationLocationBottomSheetActionBar(
                        coordinate: observationMapItem.coordinate,
                        favoriteCount: viewModel.favoriteCount,
                        currentUserFavorite: viewModel.currentUserFavorite,
                        favoriteAction: ObservationActions.favorite(
                            observationUri: viewModel.observationMapItem?.observationId,
                            userRemoteId: viewModel.currentUser?.remoteId
                        ),
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
