//
//  StaticLayer+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/18/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

extension StaticLayer {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StaticLayer> {
        return NSFetchRequest<StaticLayer>(entityName: "StaticLayer")
    }
    
    @NSManaged var data: [AnyHashable:Any]?
}
