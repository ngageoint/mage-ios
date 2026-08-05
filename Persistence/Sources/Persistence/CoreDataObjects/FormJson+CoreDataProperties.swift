//
//  FormJson+CoreDataProperties.swift
//  MAGE
//
//  Created by Daniel Barela on 12/7/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

public extension FormJson {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FormJson> {
        return NSFetchRequest<FormJson>(entityName: "FormJson")
    }
    
    @NSManaged var formId: NSNumber?
    @NSManaged var json: [AnyHashable : Any]?
}
