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
    @NSManaged var forms: [[AnyHashable : Any]]?
    @NSManaged var name: String?
    @NSManaged var recentSortOrder: NSNumber?
    @NSManaged var remoteId: NSNumber?
    @NSManaged var maxObservationForms: NSNumber?
    @NSManaged var minObservationForms: NSNumber?
    @NSManaged var teams: Set<Team>?
    @NSManaged var feeds: Set<Feed>?
    @NSManaged var acl:[AnyHashable : Any]?
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

//#import "Event+CoreDataProperties.h"

//@interface Event (CoreDataProperties)
//
//@property (nullable, nonatomic, retain) NSString *eventDescription;
//@property (nullable, nonatomic, retain) id forms;
//@property (nullable, nonatomic, retain) NSString *name;
//@property (nullable, nonatomic, retain) NSNumber *recentSortOrder;
//@property (nullable, nonatomic, retain) NSNumber *remoteId;
//@property (nullable, nonatomic, retain) NSNumber *maxObservationForms;
//@property (nullable, nonatomic, retain) NSNumber *minObservationForms;
//@property (nullable, nonatomic, retain) NSSet<Team *> *teams;
//@property (nullable, nonatomic, retain) NSSet<Feed *> *feeds;
//@property (nullable, nonatomic, retain) NSDictionary *acl;
//
//@end
//
//@interface Event (CoreDataGeneratedAccessors)
//
//- (void)addTeamsObject:(Team *)value;
//- (void)removeTeamsObject:(Team *)value;
//- (void)addTeams:(NSSet<Team *> *)values;
//- (void)removeTeams:(NSSet<Team *> *)values;
//- (void)addFeedsObject:(Team *)value;
//- (void)removeFeedsObject:(Team *)value;
//- (void)addFeeds:(NSSet<Team *> *)values;
//- (void)removeFeeds:(NSSet<Team *> *)values;
//
//@end
//
//@implementation Event (CoreDataProperties)
//
//@dynamic eventDescription;
//@dynamic forms;
//@dynamic name;
//@dynamic recentSortOrder;
//@dynamic remoteId;
//@dynamic maxObservationForms;
//@dynamic minObservationForms;
//@dynamic teams;
//@dynamic feeds;
//@dynamic acl;
//
//@end
