//
//  FeedRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/17/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct FeedItemRepositoryProviderKey: InjectionKey {
    static var currentValue: FeedItemRepository = FeedItemRepository()
}

extension InjectedValues {
    var feedItemRepository: FeedItemRepository {
        get { Self[FeedItemRepositoryProviderKey.self] }
        set { Self[FeedItemRepositoryProviderKey.self] = newValue }
    }
}

struct FeedItemModel {
    let feedItemId: URL
    let properties: Any?
    let remoteId: String?
    let temporalSortValue: Int?
    let coordinate: CLLocationCoordinate2D
    let iconUrl: URL?
    let primaryValue: String?
    let secondaryValue: String?
    let timestamp: Date?
    
    init(feedItem: FeedItem) {
        self.feedItemId = feedItem.objectID.uriRepresentation()
        self.properties = feedItem.properties
        self.remoteId = feedItem.remoteId
        if let temporalSortValue = feedItem.temporalSortValue {
            self.temporalSortValue = Int(truncating: temporalSortValue)
        } else {
            self.temporalSortValue = nil
        }
        self.coordinate = feedItem.coordinate
        self.iconUrl = feedItem.iconURL
        self.primaryValue = feedItem.primaryValue
        self.secondaryValue = feedItem.secondaryValue
        self.timestamp = feedItem.timestamp
    }
}

class FeedItemRepository: ObservableObject {
    @Injected(\.feedItemLocalDataSource)
    var localDataSource: FeedItemLocalDataSource

    func getFeedItem(feedItemrUri: URL?) async -> FeedItem? {
        await localDataSource.getFeedItem(feedItemrUri: feedItemrUri)
    }
    
    func observeFeedItem(feedItemUri: URL?) -> AnyPublisher<FeedItemModel, Never>? {
        localDataSource.observeFeedItem(feedItemUri: feedItemUri)
    }
}
