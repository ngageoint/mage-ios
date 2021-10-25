//
//  Location+CoreDataProperties.m
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

extension Location {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }
    
    @NSManaged var eventId: NSNumber?
    @NSManaged var geometryData: Data?
    @NSManaged var properties: [AnyHashable : Any]?
    @NSManaged var remoteId: String?
    @NSManaged var timestamp: Date?
    @NSManaged var type: String?
    @NSManaged var user: User?
    
}
