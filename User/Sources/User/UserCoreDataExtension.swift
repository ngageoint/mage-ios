//
//  File.swift
//  User
//
//

import Foundation
import Persistence

public extension User {
    var isPopulated: Bool {
        lastUpdated != nil
    }
    
    @objc var hasEditPermission: Bool {
        get {
            if let permissions = self.role?.permissions {
                return permissions.contains { permission in
                    return permission == PermissionsKey.UPDATE_OBSERVATION_ALL.key || permission == PermissionsKey.UPDATE_OBSERVATION_EVENT.key;
                }
            }
            return false;
        }
    }
    
    var hasCreatePermission: Bool {
        get {
            if let permissions = self.role?.permissions {
                return permissions.contains { permission in
                    return permission == PermissionsKey.CREATE_OBSERVATION.key;
                }
            }
            return false;
        }
    }
    
    @objc var cacheAvatarUrl: String? {
        get {
            let lastUpdated = String(Int(self.lastUpdated?.timeIntervalSince1970 ?? 0))
            if let avatarUrl = self.avatarUrl {
                return  "\(avatarUrl)?_lastUpdated=\(lastUpdated)"
            }
            return nil;
        }
    }
}
