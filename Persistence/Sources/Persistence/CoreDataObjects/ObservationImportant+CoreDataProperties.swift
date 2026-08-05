//
//  ObservationImportant+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

public extension ObservationImportant {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ObservationImportant> {
        return NSFetchRequest<ObservationImportant>(entityName: "ObservationImportant")
    }
    
    @NSManaged var dirty: Bool
    @NSManaged var important: Bool
    @NSManaged var timestamp: Date?
    @NSManaged var reason: String?
    @NSManaged var userId: String?
    @NSManaged var observation: Observation?
    
}
