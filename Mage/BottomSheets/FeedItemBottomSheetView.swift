//
//  FeedItemBottomSheetView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import MaterialViews

class FeedItemBottomSheeViewModel: ObservableObject {
    @Injected(\.feedItemRepository)
    var repository: FeedItemRepository
    
    var disposables = Set<AnyCancellable>()
    
    @Published
    var feedItem: FeedItemModel?
    
    var feedItemUri: URL?
    
    init(feedItemUri: URL?) {
        self.feedItemUri = feedItemUri
        repository.observeFeedItem(feedItemUri: feedItemUri)?
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] updatedObject in
                self?.feedItem = updatedObject
            })
            .store(in: &disposables)
    }
}

struct FeedItemBottomSheet: View {
    @ObservedObject
    var viewModel: FeedItemBottomSheeViewModel
    
    var body: some View {
        Group {
            if let feedItem = viewModel.feedItem {
                VStack(spacing: 0) {
                    FeedItemSummaryView(
                        timestamp: feedItem.timestamp,
                        primaryValue: feedItem.primaryValue,
                        secondaryValue: feedItem.secondaryValue,
                        iconUrl: feedItem.iconUrl
                    )
                    
                    StaticLayerFeatureBottomSheetActionBar(
                        coordinate: feedItem.coordinate,
                        navigateToAction: CoordinateActions.navigateTo(
                            coordinate: feedItem.coordinate,
                            itemKey: feedItem.feedItemId.absoluteString,
                            dataSource: DataSources.featureItem
                        )
                    )
                    
                    Button {
                        // let the ripple dissolve before transitioning otherwise it looks weird
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: .ViewFeedItem, object: feedItem.feedItemId)
                        }
                    } label: {
                        Text("More Details")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MaterialButtonStyle(type: .contained))
                    .padding(8)
                }
                .id("\(viewModel.feedItemUri?.absoluteString ?? "")")
                .ignoresSafeArea()
            }
        }
        .animation(.default, value: self.viewModel.feedItem != nil)
    }
}
