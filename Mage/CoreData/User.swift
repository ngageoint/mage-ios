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

@objc public class User: NSManagedObject, Navigable {
    
    var cllocation: CLLocation? {
        get {
            return location?.location
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return location?.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }
    
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
        return context.performAndWait {
            let user = User(context: context);
            user.update(json: json, context: context);
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
            return user;
        }
    }
    
    @objc public static func fetchUser(userId: String, context:NSManagedObjectContext) -> User? {
        return context.performAndWait {
            return context.fetchFirst(User.self, key: UserKey.remoteId.key, value: userId)
        }
    }
    
    @objc public static func fetchCurrentUser(context: NSManagedObjectContext) -> User? {
        if let fetchedUser = User.userCache[UserDefaults.standard.currentUserId ?? ""], let userInContext = context.object(with: fetchedUser.objectID) as? User {
            return userInContext
        } else {
            MageLogger.misc.debug("XXX current user \(String(describing: UserDefaults.standard.currentUserId))")
            return context.fetchFirst(User.self, key: UserKey.remoteId.key, value: UserDefaults.standard.currentUserId ?? "")
        }
    }
    
    @objc public static func operationToFetchMyself(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let baseURL = MageServer.baseURL() else {
            return nil
        }
        
        let url = "\(baseURL.absoluteURL)/api/users/myself";
        let manager = MageSessionManager.shared();
        let methodStart = Date()
        MageLogger.misc.debug("TIMING Fetching Myself @ \(methodStart)")
        let task = manager?.get_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            MageLogger.misc.debug("TIMING Fetched Myself. Elapsed: \(methodStart.timeIntervalSinceNow) seconds")
            
            let saveStart = Date()
            MageLogger.misc.debug("TIMING Saving Myself @ \(saveStart)")
            @Injected(\.persistence)
            var persistence: Persistence
            
            let context = persistence.getContext()
            context.performAndWait {
                guard let myself = responseObject as? [AnyHashable : Any], let userId = myself["id"] as? String else {
                    return;
                }
                if let user = User.fetchUser(userId: userId, context: context) {
                    user.update(json: myself, context: context)
                } else {
                    User.insert(json: myself, context: context)
                }
                
                do {
                    try context.save()
                    success?(task, nil)
                } catch {
                    failure?(task, error);
                }
                
            }
        }, failure: { task, error in
            if let failure = failure {
                failure(task, error);
            }
        });
        return task;
    }
    
    @discardableResult
    @objc public static func operationToFetchUser(userId: String, success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let baseURL = MageServer.baseURL() else {
            return nil
        }
        let url = "\(baseURL.absoluteURL)/api/users/\(userId)";
        let manager = MageSessionManager.shared();
        let methodStart = Date()
        MageLogger.misc.debug("TIMING Fetching User /api/users/\(userId) @ \(methodStart)")
        let task = manager?.get_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            MageLogger.misc.debug("TIMING Fetched User /api/users/\(userId) . Elapsed: \(methodStart.timeIntervalSinceNow) seconds")
            
            let saveStart = Date()
            MageLogger.misc.debug("TIMING Saving User /api/users/\(userId)  @ \(saveStart)")
            if let responseData = responseObject as? Data {
                if responseData.count == 0 {
                    MageLogger.misc.debug("Users are empty");
                    success?(task, nil);
                    return;
                }
            }
            
            guard let userJson = responseObject as? [AnyHashable : Any] else {
                success?(task, nil);
                return;
            }
            
            MagicalRecord.save { localContext in
                if let userId = userJson[UserKey.id.key] as? String {
                    
                    if let user = User.mr_findFirst(byAttribute: UserKey.remoteId.key, withValue: userId, in: localContext) {
                        // already exists in core data, lets update the object we have
                        MageLogger.misc.debug("Updating user in the database \(user.name ?? "")");
                        user.update(json: userJson, context: localContext);
                    } else {
                        // not in core data yet need to create a new managed object
                        MageLogger.misc.debug("Inserting new user into database");
                        User.insert(json: userJson, context: localContext)
                    }
                }
            } completion: { contextDidSave, error in
                MageLogger.misc.debug("TIMING Saved User /api/users/\(userId). Elapsed: \(saveStart.timeIntervalSinceNow) seconds")

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
    
    @discardableResult
    @objc public static func operationToFetchUsers(success: ((URLSessionDataTask,Any?) -> Void)?, failure: ((URLSessionDataTask?, Error) -> Void)?) -> URLSessionDataTask? {
        guard let baseURL = MageServer.baseURL() else {
            return nil
        }
        let url = "\(baseURL.absoluteURL)/api/users";
        let manager = MageSessionManager.shared();
        let methodStart = Date()
        MageLogger.misc.debug("TIMING Fetching Users @ \(methodStart)")
        let task = manager?.get_TASK(url, parameters: nil, progress: nil, success: { task, responseObject in
            MageLogger.misc.debug("TIMING Fetched Users. Elapsed: \(methodStart.timeIntervalSinceNow) seconds")
            
            let saveStart = Date()
            MageLogger.misc.debug("TIMING Saving Users @ \(saveStart)")
            if let responseData = responseObject as? Data {
                if responseData.count == 0 {
                    MageLogger.misc.debug("Users are empty");
                    success?(task, nil);
                    return;
                }
            }
            
            guard let users = responseObject as? [[AnyHashable : Any]] else {
                success?(task, nil);
                return;
            }
            
            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext?
            
            guard let context = context else {
                return
            }
            context.performAndWait {
                // Get roles
                var roleIdMap: [String : Role] = [:];
                if let roles = context.fetchAll(Role.self) {
                    for role in roles {
                        if let remoteId = role.remoteId {
                            roleIdMap[remoteId] = role
                        }
                    }
                }
                // Get the user ids to query
                var userIds: [String] = [];
                for userJson in users {
                    if let userId = userJson[UserKey.id.key] as? String {
                        userIds.append(userId);
                    }
                }
                                
                let usersMatchingIDs: [User] = (try? context.fetchObjects(User.self, predicate: NSPredicate(format: "(\(UserKey.remoteId.key) IN %@)", userIds))) ?? [];
                var userIdMap: [String : User] = [:];
                for user in usersMatchingIDs {
                    if let remoteId = user.remoteId {
                        userIdMap[remoteId] = user
                    }
                }
                
                for userJson in users {
                    // pull from query map
                    guard let userId = userJson[UserKey.id.key] as? String else {
                        continue;
                    }
                    if let user = userIdMap[userId] {
                        // already exists in core data, lets update the object we have
                        MageLogger.misc.debug("Updating user in the database \(user.name ?? "")");
                        user.update(json: userJson, context: context);
                        
                    } else {
                        // not in core data yet need to create a new managed object
                        MageLogger.misc.debug("Inserting new user into database");
                        User.insert(json: userJson, context: context)
                    }
                }
                do {
                    try context.save()
                    success?(task, nil)
                } catch {
                    failure?(task, error)
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
        self.remoteId = json[UserKey.id.key] as? String
        self.username = json[UserKey.username.key] as? String
        self.email = json[UserKey.email.key] as? String
        self.name = json[UserKey.displayName.key] as? String
        if let phones = json[UserKey.phones.key] as? [[AnyHashable : Any]], phones.count > 0 {
            self.phone = phones[0][UserPhoneKey.number.key] as? String
        }
        self.iconUrl = json[UserKey.iconUrl.key] as? String
        if let icon = json[UserKey.icon.key] as? [AnyHashable : Any] {
            self.iconText = icon[UserIconKey.text.key] as? String
            self.iconColor = icon[UserIconKey.color.key] as? String
        }
        self.avatarUrl = json[UserKey.avatarUrl.key] as? String
        self.recentEventIds = json[UserKey.recentEventIds.key] as? [NSNumber]
        
        let dateFormat = DateFormatter();
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0);
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        let posix = Locale(identifier: "en_US_POSIX");
        dateFormat.locale = posix;
        
        if let createdAtString = json[UserKey.createdAt.key] as? String {
            self.createdAt = dateFormat.date(from: createdAtString)
        }
        
        if let lastUpdatedString = json[UserKey.lastUpdated.key] as? String {
            self.lastUpdated = dateFormat.date(from: lastUpdatedString)
        }
        // go pull their icon and avatar if they got one using the image cache which will decide if we need to pull
        self.prefetchIconAndAvatar();
        
        if let userRole = json[UserKey.role.key] as? [AnyHashable : Any] {
            @Injected(\.roleLocalDataSource)
            var roleLocalDataSource: RoleLocalDataSource
            
            roleLocalDataSource.addUserToRole(
                roleJson: userRole,
                user: self,
                context: context
            )
        }
    }
    
    @objc public var hasEditPermission: Bool {
        get {
            if let permissions = self.role?.permissions {
                return permissions.contains { permission in
                    return permission == PermissionsKey.UPDATE_OBSERVATION_ALL.key || permission == PermissionsKey.UPDATE_OBSERVATION_EVENT.key;
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
            MageLogger.misc.debug("caching avatar \(url)")
            let prefetcher = ImagePrefetcher(urls: [url], options: [
                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
            ]) {
                skippedResources, failedResources, completedResources in
            }
            prefetcher.start()
        }
    }
    
}
