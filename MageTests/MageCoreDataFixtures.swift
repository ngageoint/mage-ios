//
//  MageCoreDataFixtures.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MagicalRecord
import sf_ios

@testable import MAGE

class MageCoreDataFixtures {
    
    public static func quietLogging() {
        MagicalRecord.setLoggingLevel(.warn);
    }
    
    public static func addEvent(remoteId: NSNumber = 1, name: String = "Test Event", completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            if let e: Event = Event.mr_createEntity(in: localContext) {
                e.name = name;
                e.remoteId = remoteId;
                e.eventDescription = "Test event description";
            }
        }, completion: completion)
    }
    
    public static func addFeedToEvent(eventId: NSNumber = 1, id: NSNumber = 1, title: String = "Test Feed", primaryProperty: String = "primary", secondaryProperty: String = "secondary", timestampProperty: String? = nil, style: [String: Any] = [:], completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            if let f: Feed = Feed.mr_createEntity(in: localContext) {
                f.title = title;
                f.eventId = eventId;
                f.id = id;
                f.summary = "Feed Summary";
                f.itemPrimaryProperty = primaryProperty;
                f.itemSecondaryProperty = secondaryProperty;
                f.itemTemporalProperty = timestampProperty;
                f.updateFrequency = 1.0;
                f.itemsHaveIdentity = true;
                f.style = style;
            }
        }, completion: completion)
    }
    
    public static func updateStyleForFeed(eventId: NSNumber = 1, id: NSNumber = 1, style: [String: Any] = [:], completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let feed = Feed.mr_findFirst(with: NSPredicate(format: "id = %@", argumentArray: [id]), in: localContext)
            feed?.style = style;
        }, completion: completion);
    }
    
    public static func addFeedItemToFeed(feedId: NSNumber = 1, properties: [String: Any]?, simpleFeature: SFGeometry = SFPoint(x: -105.2678, andY: 40.0085), completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let feed = Feed.mr_findFirst(with: NSPredicate(format: "id = %@", argumentArray: [feedId]), in: localContext)
            let count = FeedItem.mr_countOfEntities();
            if let f: FeedItem = FeedItem.mr_createEntity(in: localContext) {
                f.feed = feed;
                f.id = NSNumber(value: count + 1);
                if (properties != nil) {
                    f.properties = properties;
                } else {
                    f.properties = [
                        "property1": "value1"
                    ];
                }
                f.simpleFeature = simpleFeature;
            }
        }, completion: completion)
    }
    
    public static func addNonMappableFeedItemToFeed(feedId: NSNumber = 1, properties: [String: Any]?, completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let feed = Feed.mr_findFirst(with: NSPredicate(format: "id = %@", argumentArray: [feedId]), in: localContext)
            let count = FeedItem.mr_countOfEntities();
            if let f: FeedItem = FeedItem.mr_createEntity(in: localContext) {
                f.feed = feed;
                f.id = NSNumber(value: count + 1);
                if (properties != nil) {
                    f.properties = properties;
                } else {
                    f.properties = [
                        "property1": "value1"
                    ];
                }
            }
        }, completion: completion)
    }
}