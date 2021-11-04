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
    @NSManaged var attachments: NSSet?
    @NSManaged var favorites: NSSet?
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
    @NSManaged public func addToAttachments(_ values: NSSet)
    
    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)
}

// MARK: Generated accessors for favorites
extension Observation {
    
    @objc(addFavoritesObject:)
    @NSManaged public func addToFavorites(_ value: ObservationFavorite)
    
    @objc(removeFavoritesObject:)
    @NSManaged public func removeFromFavorites(_ value: ObservationFavorite)
    
    @objc(addFavorites:)
    @NSManaged public func addToFavorites(_ values: NSSet)
    
    @objc(removeFavorites:)
    @NSManaged public func removeFromFavorites(_ values: NSSet)
}

//#import "Observation+CoreDataProperties.h"

/**
 + (NSFetchRequest<Observation *> *)fetchRequest;
 
 @property (nullable, nonatomic, copy) NSString *deviceId;
 @property (nullable, nonatomic, copy) NSNumber *dirty;
 @property (nullable, nonatomic, copy) NSNumber *eventId;
 @property (nullable, nonatomic, copy) NSDictionary* error;
 @property (nullable, nonatomic, retain) NSData *geometryData;
 @property (nullable, nonatomic, copy) NSDate *lastModified;
 @property (nullable, nonatomic, copy) NSDictionary* properties;
 @property (nullable, nonatomic, copy) NSString *remoteId;
 @property (nullable, nonatomic, copy) NSNumber *state;
 @property (nullable, nonatomic, copy) NSDate *timestamp;
 @property (nullable, nonatomic, copy) NSString *url;
 @property (nullable, nonatomic, copy) NSString *userId;
 @property (nonatomic) BOOL syncing;
 @property (nullable, nonatomic, retain) NSSet<Attachment *> *attachments;
 @property (nullable, nonatomic, retain) NSSet<ObservationFavorite *> *favorites;
 @property (nullable, nonatomic, retain) ObservationImportant *observationImportant;
 @property (nullable, nonatomic, retain) User *user;
 
 @end
 
 @interface Observation (CoreDataGeneratedAccessors)
 
 - (void)addAttachmentsObject:(Attachment *)value;
 - (void)removeAttachmentsObject:(Attachment *)value;
 - (void)addAttachments:(NSSet<Attachment *> *)values;
 - (void)removeAttachments:(NSSet<Attachment *> *)values;
 
 - (void)addFavoritesObject:(ObservationFavorite *)value;
 - (void)removeFavoritesObject:(ObservationFavorite *)value;
 - (void)addFavorites:(NSSet<ObservationFavorite *> *)values;
 - (void)removeFavorites:(NSSet<ObservationFavorite *> *)values;
 */

//@implementation Observation (CoreDataProperties)
//
//+ (NSFetchRequest<Observation *> *)fetchRequest {
//	return [[NSFetchRequest alloc] initWithEntityName:@"Observation"];
//}
//
//@dynamic deviceId;
//@dynamic dirty;
//@dynamic eventId;
//@dynamic error;
//@dynamic geometryData;
//@dynamic lastModified;
//@dynamic properties;
//@dynamic remoteId;
//@dynamic state;
//@dynamic timestamp;
//@dynamic url;
//@dynamic userId;
//@dynamic syncing;
//@dynamic attachments;
//@dynamic favorites;
//@dynamic observationImportant;
//@dynamic user;
//
//@end
