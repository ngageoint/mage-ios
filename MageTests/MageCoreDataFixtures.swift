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
import Quick
import Nimble

@testable import MAGE

class MageCoreDataFixtures {
    
    public static func quietLogging() {
        MagicalRecord.setLoggingLevel(.warn);
    }
    
    public static func addLocation(userId: String = "userabc", completion: MRSaveCompletionHandler?) {
        guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: "locationsabc", ofType: "json") else {
            fatalError("locationsabc.json not found")
        }
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert locationsabc.json to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert locationsabc.json to Data")
        }
        
        guard let jsonDictionary: NSArray = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else {
            fatalError("Unable to convert locationsabc.json to JSON dictionary")
        }
        
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let userJson: [String: Any] = jsonDictionary[0] as! [String: Any];
            let userId: String = userJson["id"] as! String;
            let locations: [[String: Any]] = userJson["locations"] as! [[String: Any]];
            let user: User = User.mr_findFirst(in: localContext)!;
            if let location: Location = user.location {
                location.populateLocation(fromJson: locations);
            } else {
                let location: Location = Location.mr_createEntity(in: localContext)!;
                location.populateLocation(fromJson: locations);
                user.location = location;
            }
            
        }, completion: completion)
    }
    
    public static func addGPSLocation(userId: String = "userabc", completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let location: CLLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.1085, longitude: -104.3678), altitude: 2600, horizontalAccuracy: 4.2, verticalAccuracy: 3.1, timestamp: Date(timeIntervalSince1970: 5));
            
            let gpsLocation = GPSLocation(for: location, in: localContext);
        }, completion: completion)
    }
    
    public static func addUser(userId: String = "userabc", completion: MRSaveCompletionHandler?) {
        guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: "userabc", ofType: "json") else {
            fatalError("userabc.json not found")
        }
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert userabc.json to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert userabc.json to Data")
        }
        
        guard let jsonDictionary: NSDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as! NSDictionary else {
            fatalError("Unable to convert userabc.json to JSON dictionary")
        }
        
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let u: User = User.insert(forJson: jsonDictionary as! [AnyHashable : Any], in: localContext)
            u.remoteId = userId;
            
        }, completion: completion)
    }
    
    public static func addObservationToEvent(eventId: NSNumber = 1, completion: MRSaveCompletionHandler?) {
        guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: "observations", ofType: "json") else {
            fatalError("observations.json not found")
        }
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert observations.json to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert observations.json to Data")
        }
        
        guard let jsonDictionary: NSArray = try? JSONSerialization.jsonObject(with: jsonData, options: []) as! NSArray else {
            fatalError("Unable to convert observations.json to JSON dictionary")
        }
        
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let user = User.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: ["userabc"]), in: localContext)
            if let o: Observation = Observation.mr_createEntity(in: localContext) {
                o.populateObject(fromJson: jsonDictionary[0] as! [AnyHashable : Any])
                o.eventId = eventId;
                let user: User = User.mr_findFirst(byAttribute: "remoteId", withValue: o.userId, in: localContext)!;
                o.user = user;
            }
        }, completion: completion)
    }
    
    public static func addUnsyncedObservationToEvent(eventId: NSNumber = 1, completion: MRSaveCompletionHandler?) {
        guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: "observations", ofType: "json") else {
            fatalError("observations.json not found")
        }
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert observations.json to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert observations.json to Data")
        }
        
        guard let jsonDictionary: NSArray = try? JSONSerialization.jsonObject(with: jsonData, options: []) as! NSArray else {
            fatalError("Unable to convert observations.json to JSON dictionary")
        }
        
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let user = User.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: ["userabc"]), in: localContext)
            if let o: Observation = Observation.mr_createEntity(in: localContext) {
                o.populateObject(fromJson: jsonDictionary[0] as! [AnyHashable : Any])
                o.eventId = eventId;
                o.error = [
                    "errorStatusCode" : 503,
                    "errorMessage": "failed"
                ];
                let user: User = User.mr_findFirst(byAttribute: "remoteId", withValue: o.userId, in: localContext)!;
                o.user = user;
            }
        }, completion: completion)
    }
    
    public static func addEvent(remoteId: NSNumber = 1, name: String = "Test Event", formsJsonFile: String = "oneForm", completion: MRSaveCompletionHandler?) {
        
        guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: formsJsonFile, ofType: "json") else {
            fatalError("\(formsJsonFile).json not found")
        }
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert \(formsJsonFile).json to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert \(formsJsonFile).json to Data")
        }
        
        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else {
            fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
        }
        
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            if let e: Event = Event.mr_createEntity(in: localContext) {
                e.name = name;
                e.remoteId = remoteId;
                e.eventDescription = "Test event description";
                e.forms = jsonDictionary;
            }
        }, completion: completion)
    }
    
    public static func addFeedToEvent(eventId: NSNumber = 1, id: String = "1", title: String = "Test Feed", primaryProperty: String = "primary", secondaryProperty: String = "secondary", timestampProperty: String? = nil, mapStyle: [String: Any] = [:], completion: MRSaveCompletionHandler?) {
        
        var feedJson: [String: Any] = [
            "title": title,
            "id": id,
            "mapStyle": mapStyle,
            "itemPrimaryProperty": primaryProperty,
            "itemSecondaryProperty": secondaryProperty,
            "itemsHaveSpatialDimension": true,
            "updateFrequency": ["seconds": 1.0],
            "itemsHaveIdentity": true
        ];
        if (timestampProperty != nil) {
            feedJson["itemTemporalProperty"] = timestampProperty;
        }
        
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let remoteId: String = Feed.add(fromJson: feedJson, inEventId: eventId, in: localContext)
            print("saved feed \(id)")
            expect(remoteId) == id;
        }, completion: completion);
    }
    
    public static func updateStyleForFeed(eventId: NSNumber = 1, id: String = "1", style: [String: Any] = [:], completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let feed = Feed.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [id]), in: localContext)
            feed?.mapStyle = style;
        }, completion: completion);
    }
    
    public static func addFeedItemToFeed(feedId: String = "1", itemId: String? = nil, properties: [String: Any]?, simpleFeature: SFGeometry = SFPoint(x: -105.2678, andY: 40.0085), completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let feed = Feed.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [feedId]), in: localContext)
            let count = FeedItem.mr_countOfEntities();
            if let f: FeedItem = FeedItem.mr_createEntity(in: localContext) {
                f.feed = feed;
                f.remoteId = (itemId) ?? String(count + 1);
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
    
    public static func addNonMappableFeedItemToFeed(feedId: String = "1", properties: [String: Any]?, completion: MRSaveCompletionHandler?) {
        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let feed = Feed.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [feedId]), in: localContext)
            let count = FeedItem.mr_countOfEntities();
            if let f: FeedItem = FeedItem.mr_createEntity(in: localContext) {
                f.feed = feed;
                f.remoteId = String(count + 1);
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
    
    public static func populateFeedsFromJson(eventId: NSNumber = 1, completion: MRSaveCompletionHandler?) {
        guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: "feeds", ofType: "json") else {
            fatalError("feeds.json not found")
        }
        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert feeds.json to String")
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert feeds.json to Data")
        }

        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else {
            fatalError("Unable to convert feeds.json to JSON dictionary")
        }

        let feedIds: [String] = ["0","1","2","3"];

        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let remoteIds: [String] = Feed.populateFeeds(fromJson: jsonDictionary as! [Any], inEventId: eventId, in: localContext) as! [String]
            expect(remoteIds) == feedIds;
        }, completion: completion);
    }
    
    public static func populateFeedItemsFromJson(feedId: String = "1", completion: MRSaveCompletionHandler?) {
        guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: "feedContent", ofType: "json") else {
            fatalError("feedContent.json not found")
        }

        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            fatalError("Unable to convert feedContent.json to String")
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert feedContent.json to Data")
        }

        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? NSDictionary else {
            fatalError("Unable to convert feedContent.json to JSON dictionary")
        }
        
        guard let features = jsonDictionary.value(forKeyPath: "items.features") as? NSArray else {
            fatalError("Unable to retrieve feature array from feedContent.json")
        }

        let feedItemIds: [String] = ["0","2","3","4","5","6","7","8"];

        MagicalRecord.save({ (localContext: NSManagedObjectContext) in
            let remoteIds = Feed.populateFeedItems(fromJson: features as! [Any], inFeedId: feedId, in: localContext)
            expect(remoteIds as? [String]) == feedItemIds;
        }, completion: completion);
    }
}
