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

@objc public class Location: NSManagedObject {
    
    @objc public var geometry: SFGeometry? {
        get {
            if let geometryData = self.geometryData {
                return SFGeometryUtils.decodeGeometry(geometryData);
            }
            return nil
        }
        set {
            self.geometryData = SFGeometryUtils.encode(newValue);
        }
    }
    
    @objc public var location: CLLocation? {
        get {
            if let geometry = geometry, let centroid = SFGeometryUtils.centroid(of: geometry) {
                return CLLocation(latitude: centroid.y.doubleValue, longitude: centroid.x.doubleValue);
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
        self.remoteId = json["id"] as? String
        self.type = json["type"] as? String
        self.eventId = json["eventId"] as? NSNumber
        
        self.properties = json["properties"] as? [AnyHashable : Any]
        var date = Date();
        if let locationTimestamp = self.properties?["timestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
            formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
            date = formatter.date(from: locationTimestamp) ?? Date();
        }
        self.timestamp = date;
        
        // not quite sure why i have to do this, instead of having this on the same line as the if let...
        let jsonGeometry = json["geometry"] as? [AnyHashable : Any];
        if let jsonGeometry = jsonGeometry {
            if let parsed = GeometryDeserializer.parseGeometry(json: jsonGeometry) {
                self.geometry = parsed;
            }
        }
    }
    
    @objc public static func operationToPullLocations(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        let url = "\(MageServer.baseURL().absoluteURL)/api/events/\(Server.currentEventId())/locations/users";
        print("Trying to fetch locations from server \(url)")
        // we only need to get the most recent location
        var parameters: [AnyHashable : Any] = [
            "limit" : "1"
        ]
        if let lastLocationDate = Location.fetchLastLocationDate() {
            parameters["startDate"] = ISO8601DateFormatter.string(from: lastLocationDate, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone])
        }
        let manager = MageSessionManager.shared();
        let task = manager?.get_TASK(url, parameters: parameters, progress: nil, success: { task, responseObject in
            guard let allUserLocations = responseObject as? [[AnyHashable : Any]] else {
                success?(task, nil);
                return;
            }
            
            print("Fetched \(allUserLocations.count) locations from the server, saving to location storage");
            if allUserLocations.count == 0 {
                success?(task, responseObject)
                return;
            }
            MagicalRecord.save { localContext in
                let currentUser = User.fetchCurrentUser(context: localContext);
                
                var userIds: [String] = [];

                for user in allUserLocations {
                    if let userId = user["id"] as? String {
                        userIds.append(userId);
                    }
                }
                
                let usersMatchingIDs: [User] = User.mr_findAll(with: NSPredicate(format: "(remoteId IN %@)", userIds), in: localContext) as? [User] ?? [];

                var userIdMap: [String : User] = [:];
                for user in usersMatchingIDs {
                    if let remoteId = user.remoteId {
                        userIdMap[remoteId] = user
                    }
                }
                var newUserFound = false;
                
                for userJson in allUserLocations {
                    // pull from query map
                    guard let userId = userJson["id"] as? String, let locations = userJson["locations"] as? [[AnyHashable : Any]] else {
                        continue;
                    }
                    if (currentUser?.remoteId == userId) {
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
                    } else {
                        if (locations.count != 0) {
                            print("Could not find user for id \(userId)")
                            newUserFound = true;
                            var displayName = "unknown";
                            var username = userId
                            if let userFromJson = userJson["user"] as? [AnyHashable : Any] {
                                displayName = (userFromJson["displayName"] as? String) ?? "unknown"
                                username = (userFromJson["username"] as? String) ?? userId;
                            }
                            let userDicationary: [AnyHashable : Any] = [
                                "id": userId,
                                "username": username,
                                "displayName": displayName
                            ]
                            let user = User.insert(json: userDicationary, context: localContext);
                        }
                    }
                }
                
                if (newUserFound) {
                    // for now if we find at least one new user lets just go grab the users again
                    User.operationToFetchUsers(success: nil, failure: nil);
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
    
    static func fetchLastLocationDate() -> Date? {
        let location = Location.mr_findFirst(with: NSPredicate(format: "eventId == %@", Server.currentEventId()), sortedBy: "timestamp", ascending: false);
        
        return location?.timestamp
    }
}
