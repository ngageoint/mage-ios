//
//  User+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/19/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
    
    @NSManaged var active: NSNumber?
    @NSManaged var avatarUrl: String?
    @NSManaged var currentUser: NSNumber?
    @NSManaged var email: String?
    @NSManaged var iconUrl: String?
    @NSManaged var iconText: String?
    @NSManaged var iconColor: String?
    @NSManaged var name: String?
    @NSManaged var phone: String?
    @NSManaged var recentEventIds: [NSNumber]?
    @NSManaged var remoteId: String?
    @NSManaged var username: String?
    @NSManaged var lastUpdated: Date?
    @NSManaged var createdAt: Date?
    @NSManaged var location: Location?
    @NSManaged var observations: Set<Observation>?
    @NSManaged var role: Role?
    @NSManaged var teams: Set<Team>?
}

// MARK: Generated accessors for teams
extension User {
    
    @objc(addTeamsObject:)
    @NSManaged public func addToTeams(_ value: Team)
    
    @objc(removeTeamsObject:)
    @NSManaged public func removeFromTeams(_ value: Team)
    
    @objc(addTeams:)
    @NSManaged public func addToTeams(_ values: Set<Team>)
    
    @objc(removeTeams:)
    @NSManaged public func removeFromTeams(_ values: Set<Team>)
}

// MARK: Generated accessors for observations
extension User {
    
    @objc(addObservationsObject:)
    @NSManaged public func addToObservations(_ value: Observation)
    
    @objc(removeObservationsObject:)
    @NSManaged public func removeFromObservations(_ value: Observation)
    
    @objc(addObservations:)
    @NSManaged public func addToObservations(_ values: Set<Observation>)
    
    @objc(removeObservations:)
    @NSManaged public func removeFromObservations(_ values: Set<Observation>)
}
