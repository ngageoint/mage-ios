//
//  Observation+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/15/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

extension Observation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Observation> {
        return NSFetchRequest<Observation>(entityName: "Observation")
    }
    
    @NSManaged var deviceId: String?
    @NSManaged var dirty: Bool
    @NSManaged var eventId: NSNumber?
    @NSManaged var error: [AnyHashable : Any]?
    @NSManaged var geometryData: Data?
    @NSManaged var lastModified: Date?
    @NSManaged var properties: [AnyHashable : Any]?
    @NSManaged var remoteId: String?
    @NSManaged var state: NSNumber?
    @NSManaged var timestamp: Date?
    @NSManaged var url: String?
    @NSManaged var userId: String?
    @NSManaged var syncing: Bool
    @NSManaged var attachments: Set<Attachment>?
    @NSManaged var favorites: Set<ObservationFavorite>?
    @NSManaged var observationImportant: ObservationImportant?
    @NSManaged var user: User?
}

// MARK: Generated accessors for attachments
extension Observation {
    
    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: Attachment)
    
    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: Attachment)
    
    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: Set<Attachment>)
    
    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: Set<Attachment>)
}

// MARK: Generated accessors for favorites
extension Observation {
    
    @objc(addFavoritesObject:)
    @NSManaged public func addToFavorites(_ value: ObservationFavorite)
    
    @objc(removeFavoritesObject:)
    @NSManaged public func removeFromFavorites(_ value: ObservationFavorite)
    
    @objc(addFavorites:)
    @NSManaged public func addToFavorites(_ values: Set<Attachment>)
    
    @objc(removeFavorites:)
    @NSManaged public func removeFromFavorites(_ values: Set<Attachment>)
}
