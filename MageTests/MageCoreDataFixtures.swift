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
        return [:]
//        @Injected(\.nsManagedObjectContext)
//        var localContext: NSManagedObjectContext?
//        
//        guard let localContext = localContext else { return [:] }
////        let localContext: NSManagedObjectContext = NSManagedObjectContext.mr_default();
//
//        let cleared = [
//            String(describing: Attachment.self): Attachment.mr_truncateAll(in: localContext),
//            String(describing: Event.self): Event.mr_truncateAll(in: localContext),
//            String(describing: Form.self): Form.mr_truncateAll(in: localContext),
//            String(describing: Feed.self): Feed.mr_truncateAll(in: localContext),
//            String(describing: FeedItem.self): FeedItem.mr_truncateAll(in: localContext),
//            String(describing: GPSLocation.self): GPSLocation.mr_truncateAll(in: localContext),
//            String(describing: Layer.self): Layer.mr_truncateAll(in: localContext),
//            String(describing: Location.self): Location.mr_truncateAll(in: localContext),
//            String(describing: Observation.self): Observation.mr_truncateAll(in: localContext),
//            String(describing: ObservationFavorite.self): ObservationFavorite.mr_truncateAll(in: localContext),
//            String(describing: ObservationImportant.self): ObservationImportant.mr_truncateAll(in: localContext),
//            String(describing: ObservationLocation.self): ObservationLocation.mr_truncateAll(in: localContext),
//            String(describing: Role.self): Role.mr_truncateAll(in: localContext),
//            String(describing: Server.self): Server.mr_truncateAll(in: localContext),
//            String(describing: Team.self): Team.mr_truncateAll(in: localContext),
//            String(describing: User.self): User.mr_truncateAll(in: localContext)
//        ];
//        localContext.mr_saveToPersistentStoreAndWait();
//        return cleared;
    }
    
    public static func addAttachment(
        observationUri: URL,
        remoteId: String = "attachmentabc",
        contentType: String = "image/png",
        observationFormId: String = "observationformid2",
        localPath: String
    ) -> Attachment? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return nil }
        
        return context.performAndWait {
            let attachment = Attachment(context: context)
            attachment.remoteId = remoteId
            attachment.contentType = contentType
            attachment.observationFormId = "observationformid2"
            attachment.localPath = localPath
            attachment.dirty = false
            attachment.name = URL(fileURLWithPath: localPath).lastPathComponent
            
            if let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri),
               let observation = context.object(with: objectID) as? Observation
            {
                attachment.observation = observation
                attachment.observationRemoteId = observation.remoteId
            }
            
            try? context.obtainPermanentIDs(for: [attachment])
            try? context.save()
            return attachment
        }
    }
        
    public static func addLocation(userId: String = "userabc", geometry: SFPoint? = nil, date: Date? = nil) -> Location? {
        let jsonDictionary: NSArray = parseJsonFile(jsonFile: "locationsabc") as! NSArray;
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return nil }
        return context.performAndWait({
            var l: Location?
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
            let user: User? = context.fetchFirst(User.self, key: "remoteId", value: userId)
            if let location: Location = user?.location {
                location.populate(json: locations[0]);
                l = location
            } else {
                let location: Location = Location(context: context);
                location.populate(json: locations[0]);
                user?.location = location;
                l = location
            }
            try? context.obtainPermanentIDs(for: [l!])
            try? context.save()
            return l
        })
    }
    
    public static func addGPSLocation(userId: String = "userabc", location: CLLocation? = nil) {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        return context.performAndWait({
            let location: CLLocation = location ?? CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.1085, longitude: -104.3678), altitude: 2600, horizontalAccuracy: 4.2, verticalAccuracy: 3.1, timestamp: Date(timeIntervalSince1970: 5));
            
            let gpsLocation = GPSLocation.gpsLocation(location: location, context: context);
            
            try? context.obtainPermanentIDs(for: [gpsLocation!])
            try? context.save()
        })
    }
    
    @discardableResult
    public static func addUser(userId: String = "userabc", recentEventIds: [Int]? = nil) -> User? {
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
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return nil }
        print("XXX using this context \(context)")
        return context.performAndWait {
            var u: User?
            let roleJson: [String: Any] = jsonDictionary["role"] as! [String: Any];
            var existingRole: Role? = context.fetchFirst(Role.self, key: "remoteId", value: roleJson["id"] as! String)
            if (existingRole == nil) {
                existingRole = Role.insert(json: roleJson, context: context);
                print("inserting a role");
            } else {
                print("role already existed")
            }
            print("inserting a user")
            u = User.insert(json: jsonDictionary, context: context)!
            u?.remoteId = userId;
            u?.role = existingRole;
            try? context.save()
            return u
        }
    }
    
    public static func addImageryLayer(eventId: NSNumber = 1, layerId: NSNumber = 1, format: String = "XYZ", url: String = "https://magetest/xyzlayer/{z}/{x}/{y}.png", base: Bool = true, options: [String:Any]? = nil) {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let layer = ImageryLayer(context: context)
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
            layer.populate(json, eventId: eventId)
            try? context.save()
        }
    }
    
    public static func addUserToEvent(eventId: NSNumber = 1, userId: String = "userabc") {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: "remoteId", value: userId)
            let event = context.fetchFirst(Event.self, key: "remoteId", value: eventId)
            if let teams = event?.teams, let team = teams.first {
                team.addToUsers(user!);
            }
            try? context.save()
        }
    }
    
    @discardableResult
    public static func addObservationToCurrentEvent(observationJson: [AnyHashable : Any]) -> Observation? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return nil }
        return context.performAndWait {
            var observation = Observation.create(feature: observationJson, context: context)!;
            if let importantJson: [String : Any] = observationJson["important"] as? [String : Any] {
                let important: ObservationImportant = ObservationImportant.important(json: importantJson, context: context)!
                important.observation = observation;
                observation.observationImportant = important;
            }
            observation.createObservationLocations(context: context)
            try? context.obtainPermanentIDs(for: [observation])
            try? context.save()
            return observation;
        }
    }
    
    public static func loadObservationsJson(filename: String = "observations") -> [AnyHashable : Any] {
        let jsonDictionary: [[AnyHashable : Any]] = parseJsonFile(jsonFile: filename) as! [[AnyHashable : Any]];
        return jsonDictionary[0];
    }
    
    @discardableResult
    public static func addObservationToEvent(eventId: NSNumber = 1) -> Observation? {
        let jsonDictionary : NSArray = parseJsonFile(jsonFile: "observations") as! NSArray;
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return nil }
        return context.performAndWait {
            var o: Observation?
//            MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
            let user = try? context.fetchFirst(User.self, predicate: NSPredicate(format: "remoteId = %@", argumentArray: ["userabc"]))
                o = Observation.create(feature: jsonDictionary[0] as! [AnyHashable : Any], context: context)!;
                o?.eventId = eventId;
                o?.populate(json: jsonDictionary[0] as! [AnyHashable : Any])
                o?.user = user;
            o?.createObservationLocations(context: context)
//            })
            try? context.save()
            return o
        }
    }
    
    public static func addUnsyncedObservationToEvent(eventId: NSNumber = 1) {
        let jsonDictionary : NSArray = parseJsonFile(jsonFile: "observations") as! NSArray;
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let user = try? context.fetchFirst(User.self, predicate: NSPredicate(format: "remoteId = %@", argumentArray: ["userabc"]))
            let o: Observation = Observation(context: context)
            o.eventId = eventId;
            o.populate(json: jsonDictionary[0] as! [AnyHashable : Any])
            o.error = [
                "errorStatusCode" : 503,
                "errorMessage": "failed"
            ];
            o.createObservationLocations(context: context)
            o.user = user;
                
            try? context.save()
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
    
    public static func addEvent(remoteId: NSNumber = 1, name: String = "Test Event", description: String = "Test event description", formsJsonFile: String = "oneForm", maxObservationForms: NSNumber? = nil, minObservationForms: NSNumber? = nil) {
        let jsonDictionary = parseJsonFile(jsonFile: formsJsonFile, forceArray: true)
        
        MageCoreDataFixtures.addEventFromJson(remoteId: remoteId, name: name, description: description, formsJson: jsonDictionary as! [[AnyHashable : Any]], maxObservationForms: maxObservationForms, minObservationForms: minObservationForms);
    }
    
    public static func addEventFromJson(remoteId: NSNumber = 1, name: String = "Test Event", description: String = "Test event description", formsJson: [[AnyHashable: Any]], maxObservationForms: NSNumber? = nil, minObservationForms: NSNumber? = nil) {
        
        @Injected(\.teamLocalDataSource)
        var teamDataSource: TeamLocalDataSource
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let e: Event = Event(context: context)
            e.name = name;
            e.remoteId = remoteId;
            e.eventDescription = description;
            e.maxObservationForms = maxObservationForms;
            e.minObservationForms = minObservationForms;
            try? context.obtainPermanentIDs(for: [e])
            let teamJson: [String: Any] = [
                "id": "teamid",
                "name": "Team Name",
                "description": "Team Description"
            ]
            if let team = teamDataSource.updateOrInsert(json: teamJson) {
                e.addToTeams(team);
                try? context.obtainPermanentIDs(for: [team])
            }
            Form.deleteAndRecreateForms(eventId: remoteId, formsJson: formsJson, context: context)
            
            try? context.save()
        }
    }
    
    public static func addFeedToEvent(eventId: NSNumber = 1, id: String = "1", title: String = "Test Feed", primaryProperty: String = "primary", secondaryProperty: String = "secondary", timestampProperty: String? = nil, mapStyle: [String: Any] = [:]) {
        
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
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let remoteId: String = Feed.addFeed(json: feedJson, eventId: eventId, context: context)!
            print("saved feed \(id)")
            expect(remoteId) == id;
            try? context.save()
        }
    }
    
    public static func updateStyleForFeed(eventId: NSNumber = 1, id: String = "1", style: [String: Any] = [:]) {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let feed = try? context.fetchFirst(Feed.self, predicate: NSPredicate(format: "remoteId = %@", argumentArray: [id]))
                feed?.mapStyle = style;
            try? context.save()
        }
    }
    
    @discardableResult
    public static func addFeedItemToFeed(feedId: String = "1", itemId: String? = nil, properties: [String: Any]? = nil, simpleFeature: SFGeometry = SFPoint(x: -105.2678, andY: 40.0085)) -> FeedItem? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return nil }
        return context.performAndWait {
            let feed = try? context.fetchFirst(Feed.self, predicate: NSPredicate(format: "remoteId = %@", argumentArray: [feedId]))
            let count = try? context.countOfObjects(FeedItem.self)
            let f: FeedItem = FeedItem(context: context)
            f.feed = feed;
            f.remoteId = (itemId) ?? String(count ?? 0 + 1);
            if (properties != nil) {
                f.properties = properties;
            } else {
                f.properties = [
                    "property1": "value1"
                ];
            }
            f.simpleFeature = simpleFeature;
            try? context.obtainPermanentIDs(for: [f])
            try? context.save()
            return f
        }
    }
    
    public static func addNonMappableFeedItemToFeed(feedId: String = "1", properties: [String: Any]?) {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let feed = try? context.fetchFirst(Feed.self, predicate: NSPredicate(format: "remoteId = %@", argumentArray: [feedId]))
            let count = try? context.countOfObjects(FeedItem.self)
            let f: FeedItem = FeedItem(context: context)
            f.feed = feed;
            f.remoteId = String(count ?? 0 + 1);
            if (properties != nil) {
                f.properties = properties;
            } else {
                f.properties = [
                    "property1": "value1"
                ];
            }
            try? context.obtainPermanentIDs(for: [f])
            try? context.save()
        }
    }
    
    public static func populateFeedsFromJson(eventId: NSNumber = 1) {
        let jsonDictionary : NSArray = parseJsonFile(jsonFile: "feeds") as! NSArray;

        let feedIds: [String] = ["0","1","2","3"];
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let remoteIds: [String] = Feed.populateFeeds(feeds: jsonDictionary as! [[AnyHashable:Any]], eventId: eventId, context: context)
            expect(remoteIds) == feedIds;
            try? context.save()
        }
    }
    
    public static func populateFeedItemsFromJson(feedId: String = "1") {
        let jsonDictionary : NSDictionary = parseJsonFile(jsonFile: "feedContent") as! NSDictionary;
        guard let features = jsonDictionary.value(forKeyPath: "items.features") as? NSArray else {
            fatalError("Unable to retrieve feature array from feedContent.json")
        }

        let feedItemIds: [String] = ["0","2","3","4","5","6","7","8"];

        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        guard let context = context else { return }
        context.performAndWait {
            let remoteIds = Feed.populateFeedItems(feedItems: features as! [[AnyHashable:Any]], feedId: feedId, eventId: 1, context: context)
            expect(remoteIds) == feedItemIds;
            try? context.save()
        }
    }
}
