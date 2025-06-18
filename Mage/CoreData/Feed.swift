//
//  Feed+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

import Foundation
import CoreData

@objc public class Feed: NSManagedObject {
    
    @objc public static func getMappableFeeds(eventId: NSNumber) -> [Feed] {
        return Feed.mr_findAll(with: NSPredicate(format: "(\(FeedKey.itemsHaveSpatialDimension.key) == 1 AND \(FeedKey.eventId.key) == %@)", eventId)) as? [Feed] ?? [];
    }
    
    @objc public static func getEventFeeds(eventId: NSNumber) -> [Feed] {
        return Feed.mr_findAll(with: NSPredicate(format: "(\(FeedKey.eventId.key) == %@)", eventId)) as? [Feed] ?? [];
    }
    
    @objc public static func populateFeeds(feeds: [[AnyHashable: Any]], eventId: NSNumber, context: NSManagedObjectContext) -> [String] {
        var feedRemoteIds: [String] = []
        var selectedFeedsForEvent: [String] = UserDefaults.standard.array(forKey: "selectedFeeds-\(eventId)") as? [String] ?? [];
        var count = Feed.mr_countOfEntities();
        for feed in feeds {
            if let remoteFeedId = Feed.feedIdFromJson(json: feed) {
                feedRemoteIds.append(remoteFeedId);
                if let f = Feed.mr_findFirst(with: NSPredicate(format: "(\(FeedKey.remoteId.key) == %@ AND \(FeedKey.eventId.key) == %@)", remoteFeedId, eventId), in: context) {
                    f.populate(json: feed, eventId: eventId, tag: f.tag ?? NSNumber(value: count));
                } else {
                    let f = Feed.mr_createEntity(in: context);
                    selectedFeedsForEvent.append(remoteFeedId);
                    f?.populate(json: feed, eventId: eventId, tag: NSNumber(value: count));
                    f?.selected = true
                    count = count + 1;
                }
            }
        }
        selectedFeedsForEvent = selectedFeedsForEvent.filter { feedRemoteId in
            return feedRemoteIds.contains(feedRemoteId)
        }
        UserDefaults.standard.setValue(selectedFeedsForEvent, forKey: "selectedFeeds-\(eventId)")
        
        return feedRemoteIds;
    }
    
    @objc public static func addFeed(json: [AnyHashable : Any], eventId: NSNumber, context: NSManagedObjectContext) -> String? {
        var selectedFeedsForEvent: [String] = UserDefaults.standard.array(forKey: "selectedFeeds-\(eventId)") as? [String] ?? [];
        let count = Feed.mr_countOfEntities();
        
        guard let remoteFeedId = Feed.feedIdFromJson(json: json) else {
            return nil;
        }
        
        if let f = Feed.mr_findFirst(with: NSPredicate(format: "(\(FeedKey.remoteId.key) == %@ AND \(FeedKey.eventId.key) == %@)", remoteFeedId, eventId), in: context) {
            f.populate(json: json, eventId: eventId, tag: f.tag ?? NSNumber(value: count));
        } else {
            let f = Feed.mr_createEntity(in: context);
            selectedFeedsForEvent.append(remoteFeedId);
            f?.populate(json: json, eventId: eventId, tag: NSNumber(value: count));
            f?.selected = true
        }
        UserDefaults.standard.setValue(selectedFeedsForEvent, forKey: "selectedFeeds-\(eventId)")
        return remoteFeedId;
    }
    
    @discardableResult @objc public static func populateFeedItems(feedItems: [[AnyHashable : Any]], feedId: String, eventId: NSNumber, context: NSManagedObjectContext) -> [String] {
        var feedItemRemoteIds: [String] = [];
        guard let feed = Feed.mr_findFirst(with: NSPredicate(format: "\(FeedKey.remoteId.key) == %@ AND \(FeedKey.eventId.key) == %@", feedId, eventId), in: context) else {
            return feedItemRemoteIds;
        }
        for feedItem in feedItems {
            if let remoteFeedItemId = FeedItem.feedItemIdFromJson(json: feedItem) {
                feedItemRemoteIds.append(remoteFeedItemId)
                let fi = FeedItem.mr_findFirst(with: NSPredicate(format: "(\(FeedItemKey.remoteId.key) == %@ AND feed == %@)", remoteFeedItemId, feed), in: context) ?? FeedItem.mr_createEntity(in: context);
                fi?.populate(json: feedItem, feed: feed);
            }
        }
        
        FeedItem.mr_deleteAll(matching: NSPredicate(format: "(NOT (\(FeedItemKey.remoteId.key) IN %@)) AND feed == %@", feedItemRemoteIds, feed), in: context);
        return feedItemRemoteIds;
    }
    
    @objc public static func feedIdFromJson(json: [AnyHashable: Any]) -> String? {
        return json[FeedKey.id.key] as? String;
    }
    
    @objc public static func operationToPullFeeds(eventId: NSNumber, success: ((URLSessionDataTask?, Any?) -> Void)?, failure: ((Error) -> Void)?) -> URLSessionDataTask? {
        guard let baseURL = MageServer.baseURL() else {
            return nil
        }
        var feedRemoteIds: [String] = [];
        let url = "\(baseURL.absoluteURL)/api/events/\(eventId)/feeds";
        let manager = MageSessionManager.shared();
        let methodStart = Date()
        NSLog("TIMING Fetching Feeds @ \(methodStart)")
        let task = manager?.get_TASK(url, parameters: nil, progress: nil,
            success: { task, responseObject in
            NSLog("TIMING Fetched Feeds. Elapsed: \(methodStart.timeIntervalSinceNow) seconds")

            let saveStart = Date()
            NSLog("TIMING Saving Feeds @ \(saveStart)")
                MagicalRecord.save({ localContext in
                    if let feedsJson = responseObject as? [[AnyHashable : Any]] {
                        feedRemoteIds = Feed.populateFeeds(feeds: feedsJson, eventId: eventId, context: localContext);
                        for feedRemoteId in feedRemoteIds {
                            Feed.pullFeedItems(feedId: feedRemoteId, eventId: eventId, success: nil, failure: nil);
                        }
                        Feed.mr_deleteAll(matching: NSPredicate(format: "(NOT (\(FeedKey.remoteId.key) IN %@)) AND \(FeedKey.eventId.key) == %@", feedRemoteIds, eventId), in: localContext)
                    }
                }, completion: { contextDidSave, error in
                    NSLog("TIMING Saved Feeds. Elapsed: \(saveStart.timeIntervalSinceNow) seconds")

                    if let error = error {
                        if let failure = failure {
                            failure(error);
                        }
                    } else if let success = success {
                        success(task, nil);
                    }
                })
            }, failure: { task, error in
                if let failure = failure {
                    failure(error);
                }
            });
        return task;
    }
    
    @objc public static func operationToPullFeedItemsForFeed(feedId: String, eventId: NSNumber, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let baseURL = MageServer.baseURL() else {
            return nil
        }
        let url = "\(baseURL.absoluteURL)/api/events/\(eventId)/feeds/\(feedId)/content";
        let manager = MageSessionManager.shared();
        let methodStart = Date()
        NSLog("TIMING Fetching Feed Items /api/events/\(eventId)/feeds/\(feedId)/content @ \(methodStart)")
        let task = manager?.post_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            NSLog("TIMING Fetched Feed Items /api/events/\(eventId)/feeds/\(feedId)/content. Elapsed: \(methodStart.timeIntervalSinceNow) seconds")

            let saveStart = Date()
            NSLog("TIMING Saving Feed Items /api/events/\(eventId)/feeds/\(feedId)/content @ \(saveStart)")
            MagicalRecord.save { localContext in
                if let json = responseObject as? [AnyHashable : Any], let items = json[FeedKey.items.key] as? [AnyHashable : Any], let features = items[FeedKey.features.key] as? [[AnyHashable : Any]] {
                    Feed.populateFeedItems(feedItems: features, feedId: feedId, eventId: eventId, context: localContext);
                }
            } completion: { contextDidSave, error in
                NSLog("TIMING Saved Feed Items. Elapsed: \(saveStart.timeIntervalSinceNow) seconds")
                if let error = error {
                    if let failure = failure {
                        failure(task, error);
                    }
                } else if let success = success {
                    success(task, nil);
                }
            }

        }, failure: { task, error in
            if let failure = failure {
                failure(task, error);
            }
        });
        return task;
    }
    
    @objc public static func refreshFeeds(eventId: NSNumber) {
        let manager = MageSessionManager.shared();
        let task = Feed.operationToPullFeeds(eventId: eventId, success: nil, failure: nil);
        manager?.addTask(task);
    }
    
    @objc public static func pullFeedItems(feedId: String, eventId: NSNumber, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) {
        let manager = MageSessionManager.shared();
        let task = Feed.operationToPullFeedItemsForFeed(feedId: feedId, eventId: eventId, success: success, failure: failure);
        manager?.addTask(task);
    }
    
    @objc public var iconURL: URL? {
        if let mapStyle = self.mapStyle, let icon = mapStyle[FeedMapStyleKey.icon.key] as? [AnyHashable : Any], let iconId = icon[FeedMapStyleKey.id.key] as? String, let baseURL = MageServer.baseURL() {
            return URL(string: "\(baseURL.absoluteString)/api/icons/\(iconId)/content")
        }
        return nil;
    }
    
    @objc public var tabIconURL: URL? {
        // TODO: get the feed icon when we set it properly on the server
//        if let icon = icon, let iconId = icon[FeedMapStyleKey.id.key] as? String, let baseURL = MageServer.baseURL() {
//            return URL(string: "\(baseURL.absoluteString)/api/icons/\(iconId)/content")
//        }
        return nil;
    }
    
    @objc public func populate(json: [AnyHashable : Any], eventId: NSNumber, tag: NSNumber) {
        self.remoteId = json[FeedKey.id.key] as? String
        self.tag = tag
        self.title = json[FeedKey.title.key] as? String
        self.summary = json[FeedKey.summary.key] as? String
        self.constantParams = json[FeedKey.constantParams.key]
        self.variableParams = json[FeedKey.variableParams.key]
        self.updateFrequency = json[FeedKey.updateFrequencySeconds.key] as? NSNumber
        self.pullFrequency = json[FeedKey.updateFrequencySeconds.key] as? NSNumber
        self.mapStyle = json[FeedKey.mapStyle.key] as? [AnyHashable : Any]
        self.itemPropertiesSchema = json[FeedKey.itemPropertiesSchema.key] as? [AnyHashable : Any]
        self.itemPrimaryProperty = json[FeedKey.itemPrimaryProperty.key] as? String
        self.itemSecondaryProperty = json[FeedKey.itemSecondaryProperty.key] as? String
        self.itemTemporalProperty = json[FeedKey.itemTemporalProperty.key] as? String
        self.itemsHaveIdentity = (json[FeedKey.itemsHaveIdentity.key] as? Bool) ?? false
        self.itemsHaveSpatialDimension = (json[FeedKey.itemsHaveSpatialDimension.key] as? Bool) ?? false
        self.icon = json[FeedKey.icon.key] as? [AnyHashable : Any]
        self.eventId = eventId;
    }
    
}
