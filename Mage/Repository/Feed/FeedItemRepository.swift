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
    static var currentValue: FeedItemRepository = FeedItemRepositoryImpl()
}

extension InjectedValues {
    var feedItemRepository: FeedItemRepository {
        get { Self[FeedItemRepositoryProviderKey.self] }
        set { Self[FeedItemRepositoryProviderKey.self] = newValue }
    }
}

protocol FeedItemRepository {
    func getFeedItemModel(feedItemUri: URL?) async -> FeedItemModel?
    func getFeedItem(feedItemrUri: URL?) async -> FeedItem?
    func observeFeedItem(feedItemUri: URL?) -> AnyPublisher<FeedItemModel, Never>?
}

struct FeedItemModel {
    var feedItemId: URL
    var properties: Any?
    var remoteId: String?
    var temporalSortValue: Int?
    var coordinate: CLLocationCoordinate2D
    var primaryValue: String?
    var secondaryValue: String?
    var timestamp: Date?
    var title: String?
    var iconURL: URL?
}

extension FeedItemModel {
    
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
        self.primaryValue = feedItem.primaryValue
        self.secondaryValue = feedItem.secondaryValue
        self.timestamp = feedItem.timestamp
        self.title = feedItem.title
        self.iconURL = feedItem.iconURL
    }
}

class FeedItemRepositoryImpl: ObservableObject, FeedItemRepository {
    @Injected(\.feedItemLocalDataSource)
    var localDataSource: FeedItemLocalDataSource
    
    func getFeedItemModel(feedItemUri: URL?) async -> FeedItemModel? {
        await localDataSource.getFeedItemModel(feedItemUri: feedItemUri)
    }

    func getFeedItem(feedItemrUri: URL?) async -> FeedItem? {
        await localDataSource.getFeedItem(feedItemrUri: feedItemrUri)
    }
    
    func observeFeedItem(feedItemUri: URL?) -> AnyPublisher<FeedItemModel, Never>? {
        localDataSource.observeFeedItem(feedItemUri: feedItemUri)
    }
}
