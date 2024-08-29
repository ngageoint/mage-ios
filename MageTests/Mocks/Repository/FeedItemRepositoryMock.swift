//
//  FeedItemRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class FeedItemRepositoryMock: FeedItemRepository {
    var items: [FeedItemModel] = []
    
    func getFeedItemModel(feedItemUri: URL?) async -> FeedItemModel? {
        items.first { item in
            item.feedItemId == feedItemUri
        }
    }

    func getFeedItem(feedItemrUri: URL?) async -> FeedItem? {
         return nil
    }
    
    func observeFeedItem(feedItemUri: URL?) -> AnyPublisher<FeedItemModel, Never>? {
        if let item = items.first(where: { model in
            model.feedItemId == feedItemUri
        }) {
            AnyPublisher(Just(item))
        } else {
            nil
        }
    }
}
