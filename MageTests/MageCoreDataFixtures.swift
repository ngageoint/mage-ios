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
import OHHTTPStubs

@testable import MAGE

class MageCoreDataFixtures {
    
    public static func quietLogging() {
        MagicalRecord.setLoggingLevel(.warn);
    }
    
    @discardableResult
    public static func clearAllData() -> [String: Bool] {
        @Injected(\.nsManagedObjectContext)
        var localContext: NSManagedObjectContext?
        
        guard let localContext = localContext else { return [:] }
//        let localContext: NSManagedObjectContext = NSManagedObjectContext.mr_default();

        let cleared = [
            String(describing: Attachment.self): Attachment.mr_truncateAll(in: localContext),
            String(describing: Event.self): Event.mr_truncateAll(in: localContext),
            String(describing: Form.self): Form.mr_truncateAll(in: localContext),
            String(describing: Feed.self): Feed.mr_truncateAll(in: localContext),
            String(describing: FeedItem.self): FeedItem.mr_truncateAll(in: localContext),
            String(describing: GPSLocation.self): GPSLocation.mr_truncateAll(in: localContext),
            String(describing: Layer.self): Layer.mr_truncateAll(in: localContext),
            String(describing: Location.self): Location.mr_truncateAll(in: localContext),
            String(describing: Observation.self): Observation.mr_truncateAll(in: localContext),
            String(describing: ObservationFavorite.self): ObservationFavorite.mr_truncateAll(in: localContext),
            String(describing: ObservationImportant.self): ObservationImportant.mr_truncateAll(in: localContext),
            String(describing: ObservationLocation.self): ObservationLocation.mr_truncateAll(in: localContext),
            String(describing: Role.self): Role.mr_truncateAll(in: localContext),
            String(describing: Server.self): Server.mr_truncateAll(in: localContext),
            String(describing: Team.self): Team.mr_truncateAll(in: localContext),
            String(describing: User.self): User.mr_truncateAll(in: localContext)
        ];
        localContext.mr_saveToPersistentStoreAndWait();
        return cleared;
    }
        
    public static func addLocation(userId: String = "userabc", geometry: SFPoint? = nil, date: Date? = nil, completion: MRSaveCompletionHandler? = nil) -> Location? {
        let jsonDictionary: NSArray = parseJsonFile(jsonFile: "locationsabc") as! NSArray;
        
        if (completion == nil) {
            var l: Location?
            MagicalRecord.save(blockAndWait:{ (localContext: NSManagedObjectContext) in
                let userJson: [String: Any] = jsonDictionary[0] as! [String: Any];
                var locations: [[String: Any]] = userJson["locations"] as! [[String: Any]];
                locations[0]["userId"] = userId
                if let geometry = geometry {
                    locations[0]["geometry"] = GeometrySerializer.serializeGeometry(geometry)
                }
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
                formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
                if let date = date {
                    var properties = locations[0]["properties"] as! [String: Any]
                    properties["timestamp"] = formatter.string(from:date)
                    locations[0]["properties"] = properties
                }
                let user: User = User.mr_findFirst(byAttribute: "remoteId", withValue: userId, in: localContext)!;
                if let location: Location = user.location {
                    location.populate(json: locations[0]);
                    l = location
                } else {
                    let location: Location = Location.mr_createEntity(in: localContext)!;
                    location.populate(json: locations[0]);
                    user.location = location;
                    l = location
                }
                
            })
            return l?.mr_(in: NSManagedObjectContext.mr_default())
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let userJson: [String: Any] = jsonDictionary[0] as! [String: Any];
                let locations: [[String: Any]] = userJson["locations"] as! [[String: Any]];
                let user: User = User.mr_findFirst(in: localContext)!;
                if let location: Location = user.location {
                    location.populate(json: locations[0]);
                } else {
                    let location: Location = Location.mr_createEntity(in: localContext)!;
                    location.populate(json: locations[0]);
                    user.location = location;
                }
                
            }, completion: completion)
            return nil
        }
    }
    
    public static func addGPSLocation(userId: String = "userabc", location: CLLocation? = nil, completion: MRSaveCompletionHandler? = nil) {
        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let location: CLLocation = location ?? CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.1085, longitude: -104.3678), altitude: 2600, horizontalAccuracy: 4.2, verticalAccuracy: 3.1, timestamp: Date(timeIntervalSince1970: 5));
                
                _ = GPSLocation.gpsLocation(location: location, context: localContext);
            })
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let location: CLLocation = location ?? CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.1085, longitude: -104.3678), altitude: 2600, horizontalAccuracy: 4.2, verticalAccuracy: 3.1, timestamp: Date(timeIntervalSince1970: 5));
                
                _ = GPSLocation.gpsLocation(location: location, context: localContext);
            }, completion: completion)
        }
    }
    
    @discardableResult
    public static func addUser(userId: String = "userabc", recentEventIds: [Int]? = nil, completion: MRSaveCompletionHandler? = nil) -> User? {
        var jsonDictionary: [AnyHashable : Any] = parseJsonFile(jsonFile: "userabc") as! [AnyHashable : Any];
        if let recentEventIds = recentEventIds {
            jsonDictionary["recentEventIds"] = recentEventIds
        }
        
        let stubPath: String! = OHPathForFile("icon27.png", self);
        
        let documentsDir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
        let iconPath = documentsDir.appendingPathComponent("icon27.png")
        do {
            try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: iconPath);
        } catch {
            print("Error", error);
        }
        
        let markerStubPath: String! = OHPathForFile("test_marker.png", self);
        let markerIconPath = documentsDir.appendingPathComponent("test_marker.png")
        do {
            try FileManager.default.copyItem(at: URL(fileURLWithPath: markerStubPath), to: markerIconPath);
        } catch {
            print("Error", error);
        }
        
        jsonDictionary["avatarUrl"] = "icon27.png";
        jsonDictionary["iconUrl"] = "test_marker.png";
        if (completion == nil) {
            var u: User?
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let roleJson: [String: Any] = jsonDictionary["role"] as! [String: Any];
                var existingRole: Role? = Role.mr_findFirst(byAttribute: "remoteId", withValue: roleJson["id"] as! String, in: localContext);
                if (existingRole == nil) {
                    existingRole = Role.insert(json: roleJson, context: localContext);
                    print("inserting a role");
                } else {
                    print("role already existed")
                }
                print("inserting a user")
                u = User.insert(json: jsonDictionary, context: localContext)!
                u?.remoteId = userId;
                u?.role = existingRole;
                
            })
            return u
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let roleJson: [String: Any] = jsonDictionary["role"] as! [String: Any];
                var existingRole: Role? = Role.mr_findFirst(byAttribute: "remoteId", withValue: roleJson["id"] as! String, in: localContext);
                if (existingRole == nil) {
                    existingRole = Role.insert(json: roleJson, context: localContext);
                    print("inserting a role");
                } else {
                    print("role already existed")
                }
                
            }) { (success, error) in
                print("role was inserted")
                MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                    print("inserting a user")
                    let roleJson: [String: Any] = jsonDictionary["role"] as! [String: Any];

                    let existingRole: Role? = Role.mr_findFirst(byAttribute: "remoteId", withValue: roleJson["id"] as! String, in: localContext);
                    let u: User = User.insert(json: jsonDictionary, context: localContext)!
                    u.remoteId = userId;
                    u.role = existingRole;
                }, completion: completion);
            }
        }
        return nil
    }
    
    public static func addImageryLayer(eventId: NSNumber = 1, layerId: NSNumber = 1, format: String = "XYZ", url: String = "https://magetest/xyzlayer/{z}/{x}/{y}.png", base: Bool = true, options: [String:Any]? = nil, completion: MRSaveCompletionHandler? = nil) {
        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let layer = ImageryLayer.mr_createEntity(in: localContext)
                let json: [AnyHashable : Any?] = [
                    LayerKey.base.key: base,
                    LayerKey.description.key: "layer description",
                    LayerKey.format.key: format,
                    LayerKey.id.key: layerId,
                    LayerKey.name.key: "layer name",
                    LayerKey.state.key: "available",
                    LayerKey.type.key: "Imagery",
                    LayerKey.url.key: url,
                    LayerKey.wms.key: options
                ]
                layer?.populate(json, eventId: eventId)
            });
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let layer = ImageryLayer.mr_createEntity(in: localContext)
                let json: [AnyHashable : Any?] = [
                    LayerKey.base.key: base,
                    LayerKey.description.key: "layer description",
                    LayerKey.format.key: format,
                    LayerKey.id.key: layerId,
                    LayerKey.name.key: "layer name",
                    LayerKey.state.key: "available",
                    LayerKey.type.key: "Imagery",
                    LayerKey.url.key: url,
                    LayerKey.wms.key: options
                ]
                layer?.populate(json, eventId: eventId)
            }, completion: completion);
        }
    }
    
    public static func addUserToEvent(eventId: NSNumber = 1, userId: String = "userabc", completion: MRSaveCompletionHandler? = nil) {
        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let user = User.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [userId]), in: localContext);
                let event = Event.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [eventId]), in: localContext);
                if let teams = event?.teams, let team = teams.first {
                    team.addToUsers(user!);
                }
            });
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let user = User.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [userId]), in: localContext);
                let event = Event.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [eventId]), in: localContext);
                if let teams = event?.teams, let team = teams.first {
                    team.addToUsers(user!);
                }
            }, completion: completion);
        }
    }
    
    @discardableResult
    public static func addObservationToCurrentEvent(observationJson: [AnyHashable : Any], completion: MRSaveCompletionHandler? = nil) -> Observation? {
        if (completion == nil){
            var observation: Observation? = nil;
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                observation = Observation.create(feature: observationJson, context: localContext);
                if let importantJson: [String : Any] = observationJson["important"] as? [String : Any] {
                    let important: ObservationImportant = ObservationImportant.important(json: importantJson, context: localContext)!
                    important.observation = observation;
                    observation?.observationImportant = important;
                }
            })
            return observation;
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                Observation.create(feature:observationJson, context: localContext);
            }, completion: completion)
        }
        return nil;
    }
    
    public static func loadObservationsJson(filename: String = "observations") -> [AnyHashable : Any] {
        let jsonDictionary: [[AnyHashable : Any]] = parseJsonFile(jsonFile: filename) as! [[AnyHashable : Any]];
        return jsonDictionary[0];
    }
    
    @discardableResult
    public static func addObservationToEvent(eventId: NSNumber = 1, completion: MRSaveCompletionHandler? = nil) -> Observation? {
        let jsonDictionary : NSArray = parseJsonFile(jsonFile: "observations") as! NSArray;

        if (completion == nil) {
            var o: Observation?
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let user = User.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: ["userabc"]), in: localContext)
                o = Observation.create(feature: jsonDictionary[0] as! [AnyHashable : Any], context: localContext)!;
                o?.eventId = eventId;
                o?.populate(json: jsonDictionary[0] as! [AnyHashable : Any])
                o?.user = user;
            })
            return o?.mr_(in: NSManagedObjectContext.mr_default())
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let user = User.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: ["userabc"]), in: localContext)
                let o: Observation = Observation.create(feature:jsonDictionary[0] as! [AnyHashable : Any], context: localContext)!;
                o.eventId = eventId;
                o.populate(json: jsonDictionary[0] as! [AnyHashable : Any])
                o.user = user;
            }, completion: completion)
            return nil
        }
    }
    
    public static func addUnsyncedObservationToEvent(eventId: NSNumber = 1, completion: MRSaveCompletionHandler? = nil) {
        let jsonDictionary : NSArray = parseJsonFile(jsonFile: "observations") as! NSArray;

        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let user = User.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: ["userabc"]), in: localContext)
                if let o: Observation = Observation.mr_createEntity(in: localContext) {
                    o.eventId = eventId;
                    o.populate(json: jsonDictionary[0] as! [AnyHashable : Any])
                    o.error = [
                        "errorStatusCode" : 503,
                        "errorMessage": "failed"
                    ];
                    o.user = user;
                }
            })
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let user = User.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: ["userabc"]), in: localContext)
                if let o: Observation = Observation.mr_createEntity(in: localContext) {
                    o.eventId = eventId;
                    o.populate(json: jsonDictionary[0] as! [AnyHashable : Any])
                    o.error = [
                        "errorStatusCode" : 503,
                        "errorMessage": "failed"
                    ];
                    o.user = user;
                }
            }, completion: completion)
        }
    }
    
    public static func parseJsonFile(jsonFile: String, forceArray: Bool = false) -> Any {
        guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: jsonFile, ofType: "json") else {
            fatalError("\(jsonFile).json not found")
        }
        var jsonString: String = "";
        do {
            jsonString = try String(contentsOfFile: pathString, encoding: .utf8);
        } catch {
            print("error parsing \(error)")
            fatalError("Unable to convert \(jsonFile).json to String")
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            fatalError("Unable to convert \(jsonFile).json to Data")
        }
        
        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) else {
            fatalError("Unable to convert \(jsonFile).json to JSON dictionary")
        }
        if (forceArray) {
            if jsonDictionary is NSArray {
                return jsonDictionary;
            }
            else {
                return [jsonDictionary];
            }
        } else {
            return jsonDictionary;
        }
    }
    
    public static func addEvent(remoteId: NSNumber = 1, name: String = "Test Event", description: String = "Test event description", formsJsonFile: String = "oneForm", maxObservationForms: NSNumber? = nil, minObservationForms: NSNumber? = nil, completion: MRSaveCompletionHandler? = nil) {
        let jsonDictionary = parseJsonFile(jsonFile: formsJsonFile, forceArray: true)
        
        MageCoreDataFixtures.addEventFromJson(remoteId: remoteId, name: name, description: description, formsJson: jsonDictionary as! [[AnyHashable : Any]], maxObservationForms: maxObservationForms, minObservationForms: minObservationForms, completion: completion);
    }
    
    public static func addEventFromJson(remoteId: NSNumber = 1, name: String = "Test Event", description: String = "Test event description", formsJson: [[AnyHashable: Any]], maxObservationForms: NSNumber? = nil, minObservationForms: NSNumber? = nil, completion: MRSaveCompletionHandler? = nil) {

        if (completion == nil) {
            MagicalRecord.save(blockAndWait:{ (localContext: NSManagedObjectContext) in
                if let e: Event = Event.mr_createEntity(in: localContext) {
                    e.name = name;
                    e.remoteId = remoteId;
                    e.eventDescription = description;
                    e.maxObservationForms = maxObservationForms;
                    e.minObservationForms = minObservationForms;
                    let teamJson: [String: Any] = [
                        "id": "teamid",
                        "name": "Team Name",
                        "description": "Team Description"
                    ]
                    let team = Team.insert(json: teamJson, context: localContext)!;
                    e.addToTeams(team);
                    Form.deleteAndRecreateForms(eventId: remoteId, formsJson: formsJson, context: localContext)
                }
            })
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                if let e: Event = Event.mr_createEntity(in: localContext) {
                    e.name = name;
                    e.remoteId = remoteId;
                    e.eventDescription = description;
                    e.maxObservationForms = maxObservationForms;
                    e.minObservationForms = minObservationForms;
                    let teamJson: [String: Any] = [
                        "id": "teamid",
                        "name": "Team Name",
                        "description": "Team Description"
                    ]
                    let team = Team.insert(json: teamJson, context: localContext)!;
                    e.addToTeams(team);
                    Form.deleteAndRecreateForms(eventId: remoteId, formsJson: formsJson, context: localContext)
                }
            }, completion: completion)
        }
    }
    
    public static func addFeedToEvent(eventId: NSNumber = 1, id: String = "1", title: String = "Test Feed", primaryProperty: String = "primary", secondaryProperty: String = "secondary", timestampProperty: String? = nil, mapStyle: [String: Any] = [:], completion: MRSaveCompletionHandler? = nil) {
        
        var feedJson: [String: Any] = [
            "title": title,
            "id": id,
            "mapStyle": mapStyle,
            "itemPrimaryProperty": primaryProperty,
            "itemSecondaryProperty": secondaryProperty,
            "itemsHaveSpatialDimension": true,
            "updateFrequencySeconds": 1.0,
            "itemsHaveIdentity": true
        ];
        if (timestampProperty != nil) {
            feedJson["itemTemporalProperty"] = timestampProperty;
        }
        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let remoteId: String = Feed.addFeed(json: feedJson, eventId: eventId, context: localContext)!
                print("saved feed \(id)")
                expect(remoteId) == id;
                localContext.mr_saveToPersistentStoreAndWait();
            });
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let remoteId: String = Feed.addFeed(json: feedJson, eventId: eventId, context: localContext)!
                print("saved feed \(id)")
                expect(remoteId) == id;
            }, completion: completion);
        }
    }
    
    public static func updateStyleForFeed(eventId: NSNumber = 1, id: String = "1", style: [String: Any] = [:], completion: MRSaveCompletionHandler? = nil) {
        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let feed = Feed.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [id]), in: localContext)
                feed?.mapStyle = style;
            });
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let feed = Feed.mr_findFirst(with: NSPredicate(format: "remoteId = %@", argumentArray: [id]), in: localContext)
                feed?.mapStyle = style;
            }, completion: completion);
        }
    }
    
    public static func addFeedItemToFeed(feedId: String = "1", itemId: String? = nil, properties: [String: Any]? = nil, simpleFeature: SFGeometry = SFPoint(x: -105.2678, andY: 40.0085), completion: MRSaveCompletionHandler? = nil) -> FeedItem? {
        if (completion == nil) {
            var feedItem: FeedItem?
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
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
                    
                    feedItem = f
                }
            });
            return feedItem?.mr_(in: NSManagedObjectContext.mr_default())
        } else {
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
            return nil
        }
    }
    
    public static func addNonMappableFeedItemToFeed(feedId: String = "1", properties: [String: Any]?, completion: MRSaveCompletionHandler? = nil) {
        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
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
            })
        } else {
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
    }
    
    public static func populateFeedsFromJson(eventId: NSNumber = 1, completion: MRSaveCompletionHandler? = nil) {
        let jsonDictionary : NSArray = parseJsonFile(jsonFile: "feeds") as! NSArray;

        let feedIds: [String] = ["0","1","2","3"];

        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let remoteIds: [String] = Feed.populateFeeds(feeds: jsonDictionary as! [[AnyHashable:Any]], eventId: eventId, context: localContext)
                expect(remoteIds) == feedIds;
            });
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let remoteIds: [String] = Feed.populateFeeds(feeds: jsonDictionary as! [[AnyHashable:Any]], eventId: eventId, context: localContext)
                expect(remoteIds) == feedIds;
            }, completion: completion);
        }
    }
    
    public static func populateFeedItemsFromJson(feedId: String = "1", completion: MRSaveCompletionHandler? = nil) {
        let jsonDictionary : NSDictionary = parseJsonFile(jsonFile: "feedContent") as! NSDictionary;
        guard let features = jsonDictionary.value(forKeyPath: "items.features") as? NSArray else {
            fatalError("Unable to retrieve feature array from feedContent.json")
        }

        let feedItemIds: [String] = ["0","2","3","4","5","6","7","8"];

        if (completion == nil) {
            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                let remoteIds = Feed.populateFeedItems(feedItems: features as! [[AnyHashable:Any]], feedId: feedId, eventId: 1, context: localContext)
                expect(remoteIds) == feedItemIds;
            });
        } else {
            MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                let remoteIds = Feed.populateFeedItems(feedItems: features as! [[AnyHashable:Any]], feedId: feedId, eventId: 1, context: localContext)
                expect(remoteIds) == feedItemIds;
            }, completion: completion);
        }
    }
}
