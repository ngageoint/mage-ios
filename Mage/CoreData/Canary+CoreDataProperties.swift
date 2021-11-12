//
//  Canary+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 8/2/18.
//  Copyright © 2018 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

extension Canary {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Canary> {
        return NSFetchRequest<Canary>(entityName: "Canary")
    }
    
    @NSManaged var launchDate: Date?
}
