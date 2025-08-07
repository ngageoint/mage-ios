//
//  ObservationSummaryView.swift
//  MAGE
//
//  Created by Dan Barela on 8/6/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher
import CoreMedia

struct ObservationSummaryViewSwiftUI: View {
    @StateObject
    var viewModel: ObservationListViewModel
    
    @EnvironmentObject
    var router: MageRouter
    
    var body: some View {
        VStack {
            Group {
                if let important = viewModel.observationImportantModel {
                    ObservationImportantViewSwiftUI(important: important)
                }
                ObservationLocationSummary(
                    timestamp: viewModel.observationModel?.timestamp,
                    user: viewModel.user?.name,
                    primaryFieldText: viewModel.primaryFeedFieldText,
                    secondaryFieldText: viewModel.secondaryFeedFieldText,
                    iconPath: viewModel.iconPath,
                    error: viewModel.observationModel?.error ?? false,
                    syncing: viewModel.observationModel?.syncing ?? false
                )
                .padding([.leading, .trailing], 16)
                .padding(.top, 16)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                router.appendRoute(ObservationRoute.detail(uri: viewModel.observationModel?.observationId))
            }
            if !(viewModel.attachments).isEmpty {
                TabView {
                    ForEach(viewModel.orderedAttachments) { attachment in
                        AttachmentPreviewView(attachment: attachment) {
                            viewModel.appendAttachmentViewRoute(router: router, attachment: attachment)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .automatic))
                .frame(height: 150)
            }
            ObservationListActionBar(
                coordinate: viewModel.observationModel?.coordinate,
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
                navigateToAction:
                    CoordinateActions.navigateTo(
                        coordinate: viewModel.observationModel?.coordinate,
                        itemKey: viewModel.observationModel?.observationId?.absoluteString,
                        dataSource: DataSources.observation
                    )
            )
        }
        .frame(maxWidth: .infinity)
        .background(Color.surfaceColor)
        .card()
    }
}
