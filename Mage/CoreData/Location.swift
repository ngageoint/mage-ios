//
//  Location.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import sf_ios
import MagicalRecord

@objc public class Location: NSManagedObject, Navigable {
    
    static func mostRecentLocationFetchedResultsController(_ user: User, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Location>? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        
        let fetchRequest = Location.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "user = %@", user)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let locationFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        locationFetchedResultsController.delegate = delegate
        do {
            try locationFetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        return locationFetchedResultsController
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }
    
    @objc public var geometry: SFGeometry? {
        get {
            if let geometryData = self.geometryData {
                return SFGeometryUtils.decodeGeometry(geometryData);
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self.geometryData = SFGeometryUtils.encode(newValue);
            }
        }
    }
    
    @objc public var location: CLLocation? {
        get {
            if let geometry = geometry, let centroid = SFGeometryUtils.centroid(of: geometry) {
                
                let dictionary: [String : Any] = self.properties as? [String : Any] ?? [:]
                return CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue),
                    altitude: dictionary["altitude"] as? CLLocationDistance ?? 0.0,
                    horizontalAccuracy: dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0,
                    verticalAccuracy: dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0,
                    timestamp: timestamp ?? Date());
            }
            return CLLocation(latitude: 0, longitude: 0);
        }
    }
    
    @objc public var sectionName: String {
        get {
            let dateFormatter = DateFormatter();
            dateFormatter.dateFormat = "yyyy-MM-dd";
            if let timestamp = self.timestamp {
                return dateFormatter.string(from: timestamp)
            }
            return "";
        }
    }
    
    @objc public func populate(json: [AnyHashable : Any]) {
        self.remoteId = json[LocationKey.id.key] as? String
        self.type = json[LocationKey.type.key] as? String
        self.eventId = json[LocationKey.eventId.key] as? NSNumber
        
        self.properties = json[LocationKey.properties.key] as? [AnyHashable : Any]
        var date = Date();
        if let locationTimestamp = self.properties?[LocationKey.timestamp.key] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
            formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
            date = formatter.date(from: locationTimestamp) ?? Date();
        }
        self.timestamp = date;
        
        // not quite sure why i have to do this, instead of having this on the same line as the if let...
        let jsonGeometry = json[LocationKey.geometry.key] as? [AnyHashable : Any];
        if let jsonGeometry = jsonGeometry {
            if let parsed = GeometryDeserializer.parseGeometry(json: jsonGeometry) {
                self.geometry = parsed;
            }
        }
    }
    
    @objc public static func operationToPullLocations(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let currentEventId = Server.currentEventId(), let baseURL = MageServer.baseURL() else {
            return nil;
        }
        let url = "\(baseURL.absoluteURL)/api/events/\(currentEventId)/locations/users";
        print("Trying to fetch locations from server \(url)")
        // we only need to get the most recent location
        var parameters: [AnyHashable : Any] = [
            "limit" : "1"
        ]
        if let lastLocationDate = Location.fetchLastLocationDate() {
            parameters["startDate"] = ISO8601DateFormatter.string(from: lastLocationDate, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone])
        }
        let manager = MageSessionManager.shared();
        let methodStart = Date()
        NSLog("TIMING Fetching Locations /api/events/\(currentEventId)/locations/users @ \(methodStart)")
        let task = manager?.get_TASK(url, parameters: parameters, progress: nil, success: { task, responseObject in
            NSLog("TIMING Fetched Locations /api/events/\(currentEventId)/locations/users. Elapsed: \(methodStart.timeIntervalSinceNow) seconds")
            guard let allUserLocations = responseObject as? [[AnyHashable : Any]] else {
                success?(task, nil);
                return;
            }
            
            print("Fetched \(allUserLocations.count) locations from the server, saving to location storage");
            if allUserLocations.count == 0 {
                success?(task, responseObject)
                return;
            }
            
            let saveStart = Date()
            NSLog("TIMING Saving Locations /api/events/\(currentEventId)/locations/users @ \(saveStart)")
            MagicalRecord.save { localContext in
                let currentUser = User.fetchCurrentUser(context: localContext);
                
                var userIds: [String] = [];

                for user in allUserLocations {
                    if let userId = user[UserKey.id.key] as? String {
                        userIds.append(userId);
                    }
                }
                
                let usersMatchingIDs: [User] = User.mr_findAll(with: NSPredicate(format: "(\(UserKey.remoteId.key) IN %@)", userIds), in: localContext) as? [User] ?? [];

                var userIdMap: [String : User] = [:];
                for user in usersMatchingIDs {
                    if let remoteId = user.remoteId {
                        userIdMap[remoteId] = user
                    }
                }
                var newUserFound = false;
                
                for userJson in allUserLocations {
                    // pull from query map
                    guard let userId = userJson[UserKey.id.key] as? String, let locations = userJson[UserKey.locations.key] as? [[AnyHashable : Any]] else {
                        continue;
                    }
                    if let user = userIdMap[userId] {
                        if let location = user.location {
                            // already exists in core data, lets update the object we have
                            location.populate(json: locations[0])
                        } else {
                            // not in core data yet need to create a new managed object
                            let location = Location.mr_createEntity(in: localContext);
                            location?.populate(json: locations[0]);
                            user.location = location;
                        }
                        
                        // this could happen if we pulled the teams and know this user belongs on a team
                        // but did not pull the user information because the bulk user pull failed
                        if user.lastUpdated == nil {
                            // new user, go fetch
                            let manager = MageSessionManager.shared();
                            
                            let fetchUserTask = User.operationToFetchUser(userId: userId) { task, response in
                                NSLog("Fetched user \(userId) successfully.")
                            } failure: { task, error in
                                NSLog("Failed to fetch user \(userId) error \(error)")
                            }
                            manager?.addTask(fetchUserTask)
                        }
                    } else {
                        if (locations.count != 0) {
                            print("Could not find user for id \(userId)")
                            newUserFound = true;
                            var displayName = "unknown";
                            var username = userId
                            if let userFromJson = userJson[LocationKey.user.key] as? [AnyHashable : Any] {
                                displayName = (userFromJson[UserKey.displayName.key] as? String) ?? "unknown"
                                username = (userFromJson[UserKey.username.key] as? String) ?? userId;
                            }
                            let userDicationary: [AnyHashable : Any] = [
                                UserKey.id.key: userId,
                                UserKey.username.key: username,
                                UserKey.displayName.key: displayName
                            ]
                            _ = User.insert(json: userDicationary, context: localContext);
                            // new user, go fetch
                            let manager = MageSessionManager.shared();
                            
                            let fetchUserTask = User.operationToFetchUser(userId: userId) { task, response in
                                NSLog("Fetched user \(userId) successfully.")
                            } failure: { task, error in
                                NSLog("Failed to fetch user \(userId) error \(error)")
                            }
                            manager?.addTask(fetchUserTask)
                        }
                    }
                }
                
                if (newUserFound) {
                    // for now if we find at least one new user lets just go grab the users again
                    User.operationToFetchUsers(success: nil, failure: nil);
                }
            } completion: { contextDidSave, error in
                NSLog("TIMING Saved Locations /api/events/\(currentEventId)/locations/users. Elapsed: \(saveStart.timeIntervalSinceNow) seconds")

                if let error = error {
                    failure?(task, error);
                } else if let success = success {
                    success(task, nil);
                }
            }
            
        }, failure: { task, error in
            failure?(task, error);
        });
        return task;
    }
    
    static func fetchLastLocationDate() -> Date? {
        if let currentEventId = Server.currentEventId() {
            let location = Location.mr_findFirst(with: NSPredicate(format: "\(LocationKey.eventId.key) == %@", currentEventId), sortedBy: LocationKey.timestamp.key, ascending: false);
            
            return location?.timestamp
        }
        return nil;
    }
}
