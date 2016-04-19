//
//  Observation+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/18/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Observation.h"

NS_ASSUME_NONNULL_BEGIN

@interface Observation (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *deviceId;
@property (nullable, nonatomic, retain) NSNumber *dirty;
@property (nullable, nonatomic, retain) NSNumber *eventId;
@property (nullable, nonatomic, retain) id geometry;
@property (nullable, nonatomic, retain) NSDate *lastModified;
@property (nullable, nonatomic, retain) id properties;
@property (nullable, nonatomic, retain) NSString *remoteId;
@property (nullable, nonatomic, retain) NSNumber *state;
@property (nullable, nonatomic, retain) NSDate *timestamp;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSString *userId;
@property (nullable, nonatomic, retain) NSSet<Attachment *> *attachments;
@property (nullable, nonatomic, retain) User *user;

@end

@interface Observation (CoreDataGeneratedAccessors)

- (void)addAttachmentsObject:(Attachment *)value;
- (void)removeAttachmentsObject:(Attachment *)value;
- (void)addAttachments:(NSSet<Attachment *> *)values;
- (void)removeAttachments:(NSSet<Attachment *> *)values;

@end

NS_ASSUME_NONNULL_END
