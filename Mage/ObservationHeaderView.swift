//
//  ObservationHeaderView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher
import SwiftUI

struct ObservationHeaderViewSwiftUI: View {
    @EnvironmentObject
    var router: MageRouter
    
    @ObservedObject
    var viewModel: ObservationViewViewModel
        
    var body: some View {
        VStack {
            ObservationSyncStatusSwiftUI(
                hasError: viewModel.observationModel?.error,
                isDirty: viewModel.observationModel?.isDirty,
                errorMessage: viewModel.observationModel?.errorMessage,
                pushedDate: viewModel.observationModel?.lastModified,
                syncNow: ObservationActions.syncNow(observationUri: viewModel.observationModel?.observationId)
            )
            .frame(maxWidth: .infinity)
            .background(Color.surfaceColor)
            .card()
            
            VStack(spacing: 0) {
                if let important = viewModel.observationImportantModel {
                    ObservationImportantViewSwiftUI(important: important)
                }
                ObservationLocationSummary(
                    timestamp: viewModel.observationModel?.timestamp,
                    user: viewModel.user?.name,
                    primaryFieldText: viewModel.primaryFieldText,
                    secondaryFieldText: viewModel.secondaryFieldText,
                    iconPath: nil, 
                    error: viewModel.observationModel?.error ?? false,
                    syncing: viewModel.observationModel?.syncing ?? false
                )
                .padding(16)
                if let observationId = viewModel.observationModel?.observationId {
                    ObservationMapItemView(observationUri: observationId)
                }
                Divider()
                if viewModel.settingImportant {
                    VStack {
                        TextField("Important Description", text: $viewModel.importantDescription, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Spacer()
                            
                            Button {
                                viewModel.cancelAction()
                            } label: {
                                Label {
                                    Text(viewModel.cancelButtonText)
                                } icon: {
                                    
                                }
                            }
                            .buttonStyle(MaterialButtonStyle(type: .text))
                            
                            Button {
                                viewModel.makeImportant()
                            } label: {
                                Label {
                                    Text("Flag As Important")
                                } icon: {
                                    
                                }
                            }
                            .buttonStyle(MaterialButtonStyle(type: .contained))
                        }
                    }.padding()
                }
                ObservationViewActionBar(
                    isImportant: viewModel.isImportant,
                    importantAction: {
                        viewModel.settingImportant = !viewModel.settingImportant
                    },
                    favoriteCount: viewModel.favoriteCount,
                    currentUserFavorite: viewModel.currentUserFavorite,
                    favoriteAction:
                        ObservationActions.favorite(
                            observationUri: viewModel.observationModel?.observationId,
                            userRemoteId: viewModel.currentUser?.remoteId
                        ),
                    showFavoritesAction: {
                        router.appendRoute(UserRoute.showFavoritedUsers(remoteIds: viewModel.observationFavoritesModel?.favoriteUsers ?? []))
                    },
                    navigateToAction:
                        CoordinateActions.navigateTo(
                            coordinate: viewModel.observationModel?.coordinate,
                            itemKey: viewModel.observationModel?.observationId?.absoluteString,
                            dataSource: DataSources.observation
                        )
                    ,
                    moreActions: {
                        router.appendRoute(BottomSheetRoute.observationMoreActions(observationUri: viewModel.observationModel?.observationId))
                    }
                )
            }
            .frame(maxWidth: .infinity)
            .background(Color.surfaceColor)
            .card()
        }
    }
}
