//
//  User.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import Kingfisher

@objc public class User: NSManagedObject {
    
    @objc public var cacheAvatarUrl: String? {
        get {
            let lastUpdated = String(format:"%.0f", (self.lastUpdated?.timeIntervalSince1970.rounded() ?? 0))
            if let avatarUrl = self.avatarUrl {
                return  "\(avatarUrl)?_lastUpdated=\(lastUpdated)"
            }
            return nil;
        }
    }
    
    @objc public var cacheIconUrl: String? {
        get {
            let lastUpdated = String(format:"%.0f", (self.lastUpdated?.timeIntervalSince1970.rounded() ?? 0))
            if let iconUrl = self.iconUrl {
                return  "\(iconUrl)?_lastUpdated=\(lastUpdated)"
            }
            return nil;
        }
    }
    
    @discardableResult
    @objc public static func insert(json: [AnyHashable : Any], context: NSManagedObjectContext) -> User? {
        let user = User.mr_createEntity(in: context);
        user?.update(json: json, context: context);
        return user;
    }
    
    @objc public static func fetchUser(userId: String, context:NSManagedObjectContext) -> User? {
        return User.mr_findFirst(byAttribute: "remoteId", withValue: userId, in: context);
    }
    
    @objc public static func fetchCurrentUser(context: NSManagedObjectContext) -> User? {
        return User.mr_findFirst(byAttribute: "remoteId", withValue: UserDefaults.standard.currentUserId ?? "", in: context);
    }
    
    @objc public static func operationToFetchMyself(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        let url = "\(MageServer.baseURL().absoluteURL)/api/users/myself";
        let manager = MageSessionManager.shared();
        let task = manager?.get_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            MagicalRecord.save { localContext in
                guard let myself = responseObject as? [AnyHashable : Any], let userId = myself["id"] as? String else {
                    return;
                }
                if let user = User.fetchUser(userId: userId, context: localContext) {
                    user.update(json: myself, context: localContext)
                } else {
                    User.insert(json: myself, context: localContext)
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
    
    @objc public static func operationToFetchUsers(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        let url = "\(MageServer.baseURL().absoluteURL)/api/users";
        let manager = MageSessionManager.shared();
        let task = manager?.get_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            if let responseData = responseObject as? Data {
                if responseData.count == 0 {
                    print("Users are empty");
                    success?(task, nil);
                    return;
                }
            }
            
            guard let users = responseObject as? [[AnyHashable : Any]] else {
                success?(task, nil);
                return;
            }
            
            MagicalRecord.save { localContext in
                // Get roles
                var roleIdMap: [String : Role] = [:];
                if let roles = Role.mr_findAll(in: localContext) as? [Role] {
                    for role in roles {
                        if let remoteId = role.remoteId {
                            roleIdMap[remoteId] = role
                        }
                    }
                }
                // Get the user ids to query
                var userIds: [String] = [];
                for userJson in users {
                    if let userId = userJson["id"] as? String {
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
                
                for userJson in users {
                    // pull from query map
                    guard let userId = userJson["id"] as? String else {
                        continue;
                    }
                    if let user = userIdMap[userId] {
                        // already exists in core data, lets update the object we have
                        print("Updating user in the database \(user.name ?? "")");
                        user.update(json: userJson, context: localContext);
                        
                    } else {
                        // not in core data yet need to create a new managed object
                        print("Inserting new user into database");
                        User.insert(json: userJson, context: localContext)
                    }
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
    
    @objc public func update(json: [AnyHashable : Any], context: NSManagedObjectContext) {
        self.remoteId = json["id"] as? String
        self.username = json["username"] as? String
        self.email = json["email"] as? String
        self.name = json["displayName"] as? String
        if let phones = json["phones"] as? [[AnyHashable : Any]], phones.count > 0 {
            self.phone = phones[0]["number"] as? String
        }
        self.iconUrl = json["iconUrl"] as? String
        if let icon = json["icon"] as? [AnyHashable : Any] {
            self.iconText = icon["text"] as? String
            self.iconColor = icon["color"] as? String
        }
        self.avatarUrl = json["avatarUrl"] as? String
        self.recentEventIds = json["recentEventIds"] as? [NSNumber]
        
        let dateFormat = DateFormatter();
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0);
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        let posix = Locale(identifier: "en_US_POSIX");
        dateFormat.locale = posix;
        
        if let createdAtString = json["createdAt"] as? String {
            self.createdAt = dateFormat.date(from: createdAtString)
        }
        
        if let lastUpdatedString = json["lastUpdated"] as? String {
            self.lastUpdated = dateFormat.date(from: lastUpdatedString)
        }
        // go pull their icon and avatar if they got one using the image cache which will decide if we need to pull
        self.prefetchIconAndAvatar();
        
        if let userRole = json["role"] as? [AnyHashable : Any] {
            if let roleId = userRole["id"] as? String, let role = Role.mr_findFirst(byAttribute: "remoteId", withValue: roleId, in: context) {
                self.role = role;
                role.addUsersObject(self);
            } else {
                let role = Role.insert(forJson: userRole, in: context);
                self.role = role;
                role.addUsersObject(self);
            }
        }
    }
    
    @objc public var hasEditPermission: Bool {
        get {
            if let permissions = self.role?.permissions as? [String] {
                return permissions.contains { permission in
                    return permission == "UPDATE_OBSERVATION_ALL" || permission == "UPDATE_OBSERVATION_EVENT";
                }
            }
            return false;
        }
    }
    
    func prefetchIconAndAvatar() {
        if let cacheIconUrl = cacheIconUrl, let url = URL(string: cacheIconUrl) {
            let prefetcher = ImagePrefetcher(urls: [url], options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                .diskCacheExpiration(.never)
            ]) {
                skippedResources, failedResources, completedResources in
            }
            prefetcher.start()
        }
        if let cacheAvatarUrl = self.cacheAvatarUrl, let url = URL(string: cacheAvatarUrl) {
            print("caching avatar \(url)")
            let prefetcher = ImagePrefetcher(urls: [url], options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
            ]) {
                skippedResources, failedResources, completedResources in
            }
            prefetcher.start()
        }
    }
    
}
