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
        return Feed.mr_findAll(with: NSPredicate(format: "(itemsHaveSpatialDimension == 1 AND eventId == %@)", eventId)) as? [Feed] ?? [];
    }
    
    @objc public static func getEventFeeds(eventId: NSNumber) -> [Feed] {
        return Feed.mr_findAll(with: NSPredicate(format: "(eventId == %@)", eventId)) as? [Feed] ?? [];
    }
    
    @objc public static func populateFeeds(feeds: [[AnyHashable: Any]], eventId: NSNumber, context: NSManagedObjectContext) -> [String] {
        var feedRemoteIds: [String] = []
        var selectedFeedsForEvent: [String] = UserDefaults.standard.array(forKey: "selectedFeeds-\(eventId)") as? [String] ?? [];
        var count = Feed.mr_countOfEntities();
        for feed in feeds {
            if let remoteFeedId = Feed.feedIdFromJson(json: feed) {
                feedRemoteIds.append(remoteFeedId);
                if let f = Feed.mr_findFirst(with: NSPredicate(format: "(remoteId == %@ AND eventId == %@)", remoteFeedId, eventId), in: context) {
                    f.populate(json: feed, eventId: eventId, tag: NSNumber(value: count));
                } else {
                    let f = Feed.mr_createEntity(in: context);
                    selectedFeedsForEvent.append(remoteFeedId);
                    f?.populate(json: feed, eventId: eventId, tag: NSNumber(value: count));
                }
                count = count + 1;
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
        
        if let f = Feed.mr_findFirst(with: NSPredicate(format: "(remoteId == %@ AND eventId == %@)", remoteFeedId, eventId), in: context) {
            f.populate(json: json, eventId: eventId, tag: NSNumber(value: count));
        } else {
            let f = Feed.mr_createEntity(in: context);
            selectedFeedsForEvent.append(remoteFeedId);
            f?.populate(json: json, eventId: eventId, tag: NSNumber(value: count));
        }
        UserDefaults.standard.setValue(selectedFeedsForEvent, forKey: "selectedFeeds-\(eventId)")
        return remoteFeedId;
    }
    
    @discardableResult @objc public static func populateFeedItems(feedItems: [[AnyHashable : Any]], feedId: String, eventId: NSNumber, context: NSManagedObjectContext) -> [String] {
        var feedItemRemoteIds: [String] = [];
        guard let feed = Feed.mr_findFirst(with: NSPredicate(format: "remoteId == %@ AND eventId == %@", feedId, eventId), in: context) else {
            return feedItemRemoteIds;
        }
        for feedItem in feedItems {
            if let remoteFeedItemId = FeedItem.feedItemIdFromJson(json: feedItem) {
                feedItemRemoteIds.append(remoteFeedItemId)
                let fi = FeedItem.mr_findFirst(with: NSPredicate(format: "(remoteId == %@ AND feed == %@)", remoteFeedItemId, feed), in: context) ?? FeedItem.mr_createEntity(in: context);
                fi?.populate(json: feedItem, feed: feed);
            }
        }
        
        FeedItem.mr_deleteAll(matching: NSPredicate(format: "(NOT (remoteId IN %@)) AND feed == %@", feedItemRemoteIds, feed), in: context);
        return feedItemRemoteIds;
    }
    
    @objc public static func feedIdFromJson(json: [AnyHashable: Any]) -> String? {
        return json["id"] as? String;
    }
    
    @objc public static func operationToPullFeeds(eventId: NSNumber, success: ((URLSessionDataTask?, Any?) -> Void)?, failure: ((Error) -> Void)?) -> URLSessionDataTask? {
        var feedRemoteIds: [String] = [];
        let url = "\(MageServer.baseURL().absoluteURL)/api/events/\(eventId)/feeds";
        let manager = MageSessionManager.shared();
        let task = manager?.get_TASK(url, parameters: nil, progress: nil,
            success: { task, responseObject in
                MagicalRecord.save({ localContext in
                    if let feedsJson = responseObject as? [[AnyHashable : Any]] {
                        feedRemoteIds = Feed.populateFeeds(feeds: feedsJson, eventId: eventId, context: localContext);
                    }
                }, completion: { contextDidSave, error in
                    if let error = error {
                        if let failure = failure {
                            failure(error);
                        }
                    } else if let success = success {
                        MagicalRecord.save({ localContext in
                            Feed.mr_deleteAll(matching: NSPredicate(format: "(NOT (remoteId IN %@)) AND eventId == %@", feedRemoteIds), in: localContext);
                        }, completion: { contextDidSave, error in
                            if let feeds = Feed.mr_findAll(with: NSPredicate(format: "eventId == %@", eventId)) as? [Feed] {
                                for feed in feeds {
                                    if let remoteId = feed.remoteId {
                                        Feed.pullFeedItems(feedId: remoteId, eventId: eventId, success: nil, failure: nil);
                                    }
                                }
                            }
                            success(task, nil);
                        });
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
        let url = "\(MageServer.baseURL().absoluteURL)/api/events/\(eventId)/feeds/\(feedId)/content";
        let manager = MageSessionManager.shared();
        let task = manager?.post_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            MagicalRecord.save { localContext in
                if let json = responseObject as? [AnyHashable : Any], let items = json["items"] as? [AnyHashable : Any], let features = items["features"] as? [[AnyHashable : Any]] {
                    Feed.populateFeedItems(feedItems: features, feedId: feedId, eventId: eventId, context: localContext);
                }
            } completion: { contextDidSave, error in
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
        if let mapStyle = self.mapStyle as? [AnyHashable : Any], let icon = mapStyle["icon"] as? [AnyHashable : Any], let iconId = icon["id"] as? String {
            return URL(string: "\(MageServer.baseURL().absoluteString)/api/icons/\(iconId)/content")
        }
        return nil;
    }
    
    @objc public func populate(json: [AnyHashable : Any], eventId: NSNumber, tag: NSNumber) {
        self.remoteId = json["id"] as? String
        self.tag = tag
        self.title = json["title"] as? String
        self.summary = json["summary"] as? String
        self.constantParams = json["constantParams"]
        self.variableParams = json["variableParams"]
        self.updateFrequency = (json["updateFrequency"] as? [AnyHashable : Any])?["seconds"] as? NSNumber
        self.pullFrequency = (json["updateFrequency"] as? [AnyHashable : Any])?["seconds"] as? NSNumber
        self.mapStyle = json["mapStyle"]
        self.itemPropertiesSchema = json["itemPropertiesSchema"]
        self.itemPrimaryProperty = json["itemPrimaryProperty"] as? String
        self.itemSecondaryProperty = json["itemSecondaryProperty"] as? String
        self.itemTemporalProperty = json["itemTemporalProperty"] as? String
        self.itemsHaveIdentity = (json["itemsHaveIdentity"] as? Bool) ?? false
        self.itemsHaveSpatialDimension = (json["itemsHaveSpatialDimension"] as? Bool) ?? false
        self.eventId = eventId;
    }
    
}
