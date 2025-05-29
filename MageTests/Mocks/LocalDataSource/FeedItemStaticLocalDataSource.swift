//
//  FeedItemStaticLocalDataSource.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class FeedItemStaticLocalDataSource: FeedItemLocalDataSource {
    var items: [FeedItemModel] = []
    
    func getFeedItemModel(feedItemUri: URL?) async -> FeedItemModel? {
        items.first { item in
            item.feedItemId == feedItemUri
        }
    }
    
    func getFeedItem(feedItemUri: URL?) async -> MAGE.FeedItem? {
        return nil
//        items.first { item in
//            item.
//        }
    }
    
    func observeFeedItem(feedItemUri: URL?) -> AnyPublisher<MAGE.FeedItemModel, Never>? {
        if let item = items.first(where: { model in
            model.feedItemId == feedItemUri
        }) {
            AnyPublisher(Just(item))
        } else {
            nil
        }
    }
}
