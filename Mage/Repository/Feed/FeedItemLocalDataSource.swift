//
//  FeedItemLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 6/17/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

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
    func getFeedItem(feedItemrUri: URL?) async -> FeedItem?
}

class FeedItemCoreDataDataSource: CoreDataDataSource, FeedItemLocalDataSource, ObservableObject {
    func getFeedItem(feedItemrUri: URL?) async -> FeedItem? {
        guard let feedItemrUri = feedItemrUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: feedItemrUri) {
                return try? context.existingObject(with: id) as? FeedItem
            }
            return nil
        }
    }
}
