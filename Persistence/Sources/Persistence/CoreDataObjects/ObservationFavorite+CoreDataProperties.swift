//
//  ObservationFavorite+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

public extension ObservationFavorite {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ObservationFavorite> {
        return NSFetchRequest<ObservationFavorite>(entityName: "ObservationFavorite")
    }
    
    @NSManaged var dirty: Bool
    @NSManaged var userId: String?
    @NSManaged var favorite: Bool
    @NSManaged var observation: Observation?
    
}
