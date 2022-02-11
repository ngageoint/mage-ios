//
//  Feed+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

import Foundation
import CoreData

extension Feed {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Feed> {
        return NSFetchRequest<Feed>(entityName: "Feed")
    }
    
    @NSManaged var remoteId: String?;
    @NSManaged var title: String?;
    @NSManaged var tag: NSNumber?;
    @NSManaged var summary: String?;
    @NSManaged var itemsHaveIdentity: Bool;
    @NSManaged var itemPrimaryProperty: String?;
    @NSManaged var itemSecondaryProperty: String?;
    @NSManaged var constantParams: Any?;
    @NSManaged var variableParams: Any?;
    @NSManaged var mapStyle: [AnyHashable : Any]?;
    @NSManaged var updateFrequency: NSNumber?;
    @NSManaged var pullFrequency: NSNumber?;
    @NSManaged var items: Set<FeedItem>;
    @NSManaged var event: Event?;
    @NSManaged var eventId: NSNumber?;
    @NSManaged var itemsHaveSpatialDimension: Bool;
    @NSManaged var itemTemporalProperty: String?;
    @NSManaged var itemPropertiesSchema: [AnyHashable : Any]?;
    @NSManaged var selected: Bool
    @NSManaged var icon: [AnyHashable : Any]?
}
