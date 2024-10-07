//
//  FeedItemBottomSheeViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

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
