//
//  Form+CoreDataProperties.swift
//  MAGE
//
//  Created by Daniel Barela on 12/2/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

extension Form {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Form> {
        return NSFetchRequest<Form>(entityName: "Form")
    }
    
    @NSManaged var formId: NSNumber?
    @NSManaged var eventId: NSNumber?
    @NSManaged var order: NSNumber?
    @NSManaged var archived: Bool
    @NSManaged var json: FormJson?
    @NSManaged var primaryFeedField: [AnyHashable : Any]?
    @NSManaged var secondaryFeedField: [AnyHashable : Any]?
    @NSManaged var primaryMapField: [AnyHashable : Any]?
    @NSManaged var secondaryMapField: [AnyHashable : Any]?
}
