//
//  Team.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

@objc public class Team: NSManagedObject {
    
    @objc public static func insert(json: [AnyHashable : Any], context: NSManagedObjectContext) -> Team? {
        let team = Team.mr_createEntity(in: context);
        team?.update(json: json, context: context);
        return team;
    }
    
    @objc public func update(json: [AnyHashable : Any], context: NSManagedObjectContext) {
        self.remoteId = json[TeamKey.id.key] as? String
        self.name = json[TeamKey.name.key] as? String
        self.teamDescription = json[TeamKey.description.key] as? String
        
        var teamUsers: Set<User> = Set<User>()
        
        if let userIds = json[TeamKey.userIds.key] as? [String] {
            for userId in userIds {
                if let user = User.mr_findFirst(byAttribute: UserKey.remoteId.key, withValue: userId, in: context) {
                    teamUsers.insert(user);
                } else {
                    if let user = User.mr_createEntity(in: context) {
                        user.remoteId = userId;
                        teamUsers.insert(user);
                    }
                }
            }
        }
        
        self.users = teamUsers
    }
}
