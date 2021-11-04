//
//  Team+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/18/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Team {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Team> {
        return NSFetchRequest<Team>(entityName: "Team")
    }
    @NSManaged var name: String?
    @NSManaged var remoteId: String?
    @NSManaged var teamDescription: String?
    @NSManaged var events: Set<Event>?
    @NSManaged var users: Set<User>?
}

// MARK: Generated accessors for events
extension Team {
    
    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: Event)
    
    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: Event)
    
    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: Set<Event>)
    
    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: Set<Event>)
}

// MARK: Generated accessors for users
extension Team {
    
    @objc(addUsersObject:)
    @NSManaged public func addToUsers(_ value: User)
    
    @objc(removeUsersObject:)
    @NSManaged public func removeFromUsers(_ value: User)
    
    @objc(addUsers:)
    @NSManaged public func addToUsers(_ values: Set<User>)
    
    @objc(removeUsers:)
    @NSManaged public func removeFromUsers(_ values: Set<User>)
}
