//
//  Layer+CoreDataProperties.m
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

extension Layer {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Layer> {
        return NSFetchRequest<Layer>(entityName: "Layer")
    }
    
    @NSManaged var eventId: NSNumber?
    @NSManaged var formId: String?
    @NSManaged var loaded: NSNumber?
    @NSManaged var name: String?
    @NSManaged var layerDescription: String?
    @NSManaged var state: String?
    @NSManaged var remoteId: NSNumber?
    @NSManaged var type: String?
    @NSManaged var url: String?
    @NSManaged var file: [AnyHashable: Any]?
    @NSManaged var downloadedBytes: NSNumber?
    @NSManaged var downloading: Bool
    @NSManaged var base: Bool
}
