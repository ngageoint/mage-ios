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

struct ObservationSummaryViewSwiftUI: View {
    @StateObject
    var viewModel: ObservationListViewModel
    
    var selectedAttachment: (_ attachmentUri: URL) -> Void
    
    var body: some View {
        VStack {
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
            if !(viewModel.attachments ?? []).isEmpty {
                TabView {
                    ForEach(viewModel.orderedAttachments ?? []) { attachment in
                        if let url = URL(string: attachment.url ?? "") {
                            KFImage(url)
                                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                                .forceRefresh()
                                .cacheOriginalImage()
                                .onlyFromCache(DataConnectionUtilities.shouldFetchAttachments())
                                .placeholder {
                                    Image("observations")
                                        .symbolRenderingMode(.monochrome)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                                }
                            
                                .fade(duration: 0.3)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: 150)
                                .onTapGesture {
                                    selectedAttachment(attachment.attachmentUri)
                                }
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
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
