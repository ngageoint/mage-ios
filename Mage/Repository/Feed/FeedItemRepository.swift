//
//  FeedRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/17/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct FeedItemRepositoryProviderKey: InjectionKey {
    static var currentValue: FeedItemRepository = FeedItemRepository()
}

extension InjectedValues {
    var feedItemRepository: FeedItemRepository {
        get { Self[FeedItemRepositoryProviderKey.self] }
        set { Self[FeedItemRepositoryProviderKey.self] = newValue }
    }
}

class FeedItemRepository: ObservableObject {
    @Injected(\.feedItemLocalDataSource)
    var localDataSource: FeedItemLocalDataSource

    func getFeedItem(feedItemrUri: URL?) async -> FeedItem? {
        await localDataSource.getFeedItem(feedItemrUri: feedItemrUri)
    }
}
