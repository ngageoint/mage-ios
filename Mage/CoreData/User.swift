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

import Persistence

extension User: Navigable {
    
    var cllocation: CLLocation? {
        get {
            if remoteId == UserDefaults.standard.currentUserId {
                let locations: [GPSLocation] = GPSLocation.fetchGPSLocations(limit: 1, context: NSManagedObjectContext.mr_default())
                if (locations.count != 0) {
                    let location: GPSLocation = locations[0]
                    return location.cllocation
                }
            } else {
                return location?.location
            }
            
            return nil
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            if remoteId == UserDefaults.standard.currentUserId {
                let locations: [GPSLocation] = GPSLocation.fetchGPSLocations(limit: 1, context: NSManagedObjectContext.mr_default())
                if (locations.count != 0) {
                    let location: GPSLocation = locations[0]
                    return location.cllocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
                }
                    
                return CLLocationCoordinate2D(latitude: 0, longitude: 0)
            }
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
        let user = User.mr_createEntity(in: context);
        user?.update(json: json, context: context);
        return user;
    }
    
    @objc public static func fetchUser(userId: String, context:NSManagedObjectContext) -> User? {
        return User.mr_findFirst(byAttribute: UserKey.remoteId.key, withValue: userId, in: context);
    }
    
    @objc public static func fetchCurrentUser(context: NSManagedObjectContext) -> User? {
        return User.mr_findFirst(byAttribute: UserKey.remoteId.key, withValue: UserDefaults.standard.currentUserId ?? "", in: context);
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
            if let roleId = userRole[RoleKey.id.key] as? String, let role = Role.mr_findFirst(byAttribute: RoleKey.remoteId.key, withValue: roleId, in: context) {
                self.role = role;
                role.addToUsers(self);
            } else {
                let role = Role.insert(json: userRole, context: context);
                self.role = role;
                role?.addToUsers(self);
            }
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
