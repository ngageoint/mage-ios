//
//  GPSLocation+CoreDataProperties.m
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

extension GPSLocation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Feed> {
        return NSFetchRequest<Feed>(entityName: "GPSLocation")
    }
    
    @NSManaged var eventId: NSNumber?;
    @NSManaged var geometryData: Data?;
    @NSManaged var properties: [AnyHashable : Any]?;
    @NSManaged var timestamp: Date?;
}

//#import "GPSLocation+CoreDataProperties.h"

//@implementation GPSLocation (CoreDataProperties)
//
//@dynamic eventId;
//@dynamic geometryData;
//@dynamic properties;
//@dynamic timestamp;

/**
 @property (nullable, nonatomic, retain) NSNumber *eventId;
 @property (nullable, nonatomic, retain) NSData *geometryData;
 @property (nullable, nonatomic, retain) id properties;
 @property (nullable, nonatomic, retain) NSDate *timestamp;
 */

//@end
