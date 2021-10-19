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
        self.remoteId = json["id"] as? String
        self.name = json["name"] as? String
        self.teamDescription = json["description"] as? String
        
        var teamUsers: [User] = [];
        
        if let userIds = json["userIds"] as? [String] {
            for userId in userIds {
                if let user = User.mr_findFirst(byAttribute: "remoteId", withValue: userId, in: context) {
                    teamUsers.append(user);
                } else {
                    if let user = User.mr_createEntity(in: context) {
                        user.remoteId = userId;
                        teamUsers.append(user)
                    }
                }
            }
        }
        
        self.users = NSSet(array: teamUsers);
    }
}
