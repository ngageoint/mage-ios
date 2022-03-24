//
//  Attachment+CoreDataProperties.m
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

extension Attachment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment")
    }
    
    @NSManaged var contentType: String?
    @NSManaged var observationFormId: String?
    @NSManaged var fieldName: String?
    @NSManaged var dirty: Bool
    @NSManaged var eventId: NSNumber?
    @NSManaged var lastModified: Date?
    @NSManaged var localPath: String?
    @NSManaged var name: String?
    @NSManaged var observationRemoteId: String?
    @NSManaged var remoteId: String?
    @NSManaged var remotePath: String?
    @NSManaged var size: NSNumber?
    @NSManaged var url: String?
    @NSManaged var observation: Observation?
    @NSManaged var taskIdentifier: NSNumber?
    @NSManaged var markedForDeletion: Bool
    @NSManaged var order: NSNumber?
}
