//
//  Feed+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

//#import "Feed+CoreDataProperties.h"
//
//@implementation Feed (CoreDataProperties)
//
//@property (nullable, nonatomic, copy) NSString* remoteId;
//@property (nullable, nonatomic, copy) NSString *title;
//@property (nullable, nonatomic, copy) NSNumber *tag;
//@property (nullable, nonatomic, copy) NSString *summary;
//@property (nonatomic) BOOL itemsHaveIdentity;
//@property (nonatomic) BOOL itemsHaveSpatialDimension;
//@property (nullable, nonatomic, copy) NSString *itemPrimaryProperty;
//@property (nullable, nonatomic, copy) NSString *itemSecondaryProperty;
//@property (nullable, nonatomic, copy) NSString *itemTemporalProperty;
//@property (nullable, nonatomic, retain) id constantParams;
//@property (nullable, nonatomic, retain) id variableParams;
//@property (nullable, nonatomic, retain) id mapStyle;
//@property (nullable, nonatomic, retain) id itemPropertiesSchema;
//@property (nullable, nonatomic, retain) NSNumber* pullFrequency;
//@property (nullable, nonatomic, retain) NSNumber* updateFrequency;
//@property (nullable, nonatomic, retain) NSSet<FeedItem *> *items;
//@property (nullable, nonatomic, retain) Event *event;
//@property (nullable, nonatomic, retain) NSNumber *eventId;
//
//+ (NSFetchRequest<Feed *> *)fetchRequest {
//	return [NSFetchRequest fetchRequestWithEntityName:@"Feed"];
//}
//
//@dynamic remoteId;
//@dynamic title;
//@dynamic tag;
//@dynamic summary;
//@dynamic itemsHaveIdentity;
//@dynamic itemPrimaryProperty;
//@dynamic itemSecondaryProperty;
//@dynamic constantParams;
//@dynamic variableParams;
//@dynamic mapStyle;
//@dynamic updateFrequency;
//@dynamic pullFrequency;
//@dynamic items;
//@dynamic event;
//@dynamic eventId;
//@dynamic itemsHaveSpatialDimension;
//@dynamic itemTemporalProperty;
//@dynamic itemPropertiesSchema;
//
//@end

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
}
