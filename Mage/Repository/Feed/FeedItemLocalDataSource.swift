//
//  FeedItemLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 6/17/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct FeedItemLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: FeedItemLocalDataSource = FeedItemCoreDataDataSource()
}

extension InjectedValues {
    var feedItemLocalDataSource: FeedItemLocalDataSource {
        get { Self[FeedItemLocalDataSourceProviderKey.self] }
        set { Self[FeedItemLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol FeedItemLocalDataSource {
    // TODO: this should go away
    @available(*, deprecated, renamed: "getFeedItemModel", message: "use the getFeedItemModel method")
    func getFeedItem(feedItemUri: URL?) async -> FeedItem?
    func getFeedItemModel(feedItemUri: URL?) async -> FeedItemModel?
    func observeFeedItem(
        feedItemUri: URL?
    ) -> AnyPublisher<FeedItemModel, Never>?
}

class FeedItemCoreDataDataSource: CoreDataDataSource<FeedItem>, FeedItemLocalDataSource, ObservableObject {
    func getFeedItemModel(feedItemUri: URL?) async -> FeedItemModel? {
        if let feedItem = await getFeedItem(feedItemUri: feedItemUri) {
            return FeedItemModel(feedItem: feedItem)
        }
        return nil
    }
    
    func getFeedItem(feedItemUri: URL?) async -> FeedItem? {
        guard let feedItemUri = feedItemUri else {
            return nil
        }
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: feedItemUri) {
                if let feedItem = try? context.existingObject(with: id) as? FeedItem {
                    return feedItem
                }
            }
            return nil
        }
    }
    
    func observeFeedItem(feedItemUri: URL?) -> AnyPublisher<FeedItemModel, Never>? {
        guard let feedItemUri = feedItemUri else {
            return nil
        }
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        return context.performAndWait {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: feedItemUri) {
                if let feedItem = try? context.existingObject(with: id) as? FeedItem {
                    return publisher(for: feedItem, in: context)
                        .prepend(feedItem)
                        .map({ feedItem in
                            return FeedItemModel(feedItem: feedItem)
                        })
                        .eraseToAnyPublisher()
                }
            }
            return nil
        }
    }
}
