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
                router.path.append(ObservationRoute.detail(uri: viewModel.observationModel?.observationId))
            }
            if !(viewModel.attachments ?? []).isEmpty {
                TabView {
                    ForEach(viewModel.orderedAttachments ?? []) { attachment in
                        if let url = URL(string: attachment.url ?? "") {
                            if (attachment.contentType?.hasPrefix("image") ?? false) {
                                KFImage(
                                    url
                                )
                                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
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
                                    viewModel.appendAttachmentViewRoute(router: router, attachment: attachment)
                                }
                            } else if (attachment.contentType?.hasPrefix("video") ?? false),
                                      let url = attachment.urlWithToken
                            {
                                KFImage(
                                    source: Source.provider(
                                        AVAssetImageDataProvider(
                                            assetURL: url,
                                            time: CMTime(seconds: 0.0, preferredTimescale: 1)
                                        )
                                    )
                                )
                                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                                .cacheOriginalImage()
                                .placeholder {
                                    Image(systemName: "play.circle.fill")
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
                                    viewModel.appendAttachmentViewRoute(router: router, attachment: attachment)
                                }
                                .overlay {
                                    Image(systemName: "play.circle.fill")
                                        .symbolRenderingMode(.monochrome)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                                        .padding(16)
                                }
                            } else if (attachment.contentType?.hasPrefix("audio") ?? false) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .symbolRenderingMode(.monochrome)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                                    .onTapGesture {
                                        viewModel.appendAttachmentViewRoute(router: router, attachment: attachment)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, maxHeight: 150)
                                    .border(.gray)
                            } else {
                                Image(systemName: "paperclip")
                                    .symbolRenderingMode(.monochrome)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                                    .onTapGesture {
                                        viewModel.appendAttachmentViewRoute(router: router, attachment: attachment)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, maxHeight: 150)
                                    .border(.gray)
                            }
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
