//
//  Observation+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation.h"


NS_ASSUME_NONNULL_BEGIN

@interface Observation (CoreDataProperties)

+ (NSFetchRequest<Observation *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *deviceId;
@property (nullable, nonatomic, copy) NSNumber *dirty;
@property (nullable, nonatomic, copy) NSNumber *eventId;
@property (nullable, nonatomic, retain) NSData *geometryData;
@property (nullable, nonatomic, copy) NSDate *lastModified;
@property (nullable, nonatomic, retain) id properties;
@property (nullable, nonatomic, copy) NSString *remoteId;
@property (nullable, nonatomic, copy) NSNumber *state;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nullable, nonatomic, copy) NSString *url;
@property (nullable, nonatomic, copy) NSString *userId;
@property (nullable, nonatomic, retain) NSObject *attribute;
@property (nullable, nonatomic, retain) NSSet<Attachment *> *attachments;
@property (nullable, nonatomic, retain) ObservationImportant *observationImportant;
@property (nullable, nonatomic, retain) User *user;
@property (nullable, nonatomic, retain) NSSet<ObservationFavorite *> *favorites;

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

@end

NS_ASSUME_NONNULL_END
