//
//  Event+CoreDataProperties.m
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

extension Event {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }
    
    @NSManaged var eventDescription: String?
    @NSManaged var name: String?
    @NSManaged var recentSortOrder: NSNumber?
    @NSManaged var remoteId: NSNumber?
    @NSManaged var maxObservationForms: NSNumber?
    @NSManaged var minObservationForms: NSNumber?
    @NSManaged var teams: Set<Team>?
    @NSManaged var feeds: Set<Feed>?
    @NSManaged var acl:[AnyHashable : Any]?
}

extension Event {
    
    var unsyncedObservations: [Observation] {
        guard let id = self.remoteId else {
            return []
        }

        let predicate = NSPredicate(format: "error != nil && eventId == %@", id)
        let fetchRequest: NSFetchRequest<Observation> = Observation.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            if let list = try self.managedObjectContext?.fetch(fetchRequest) {
                return list
            } else {
                return []
            }
        } catch let error {
            MageLogger.misc.error("error:\(error)")
            return []
        }
    }
}

// MARK: Generated accessors for teams
extension Event {
    
    @objc(addTeamsObject:)
    @NSManaged public func addToTeams(_ value: Team)
    
    @objc(removeTeamsObject:)
    @NSManaged public func removeFromTeams(_ value: Team)
    
    @objc(addTeams:)
    @NSManaged public func addToTeams(_ values: Set<Team>)
    
    @objc(removeTeams:)
    @NSManaged public func removeFromTeams(_ values: Set<Team>)
}

// MARK: Generated accessors for feeds
extension Event {
    
    @objc(addFeedsObject:)
    @NSManaged public func addToFeeds(_ value: Feed)
    
    @objc(removeFeedsObject:)
    @NSManaged public func removeFromFeeds(_ value: Feed)
    
    @objc(addFeeds:)
    @NSManaged public func addToFeeds(_ values: Set<Feed>)
    
    @objc(removeFeeds:)
    @NSManaged public func removeFromFeeds(_ values: Set<Feed>)
}
