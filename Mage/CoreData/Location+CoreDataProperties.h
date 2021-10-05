//
//  Location+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/18/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Location.h"

NS_ASSUME_NONNULL_BEGIN

@interface Location (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *eventId;
@property (nullable, nonatomic, retain) NSData *geometryData;
@property (nullable, nonatomic, retain) id properties;
@property (nullable, nonatomic, retain) NSString *remoteId;
@property (nullable, nonatomic, retain) NSDate *timestamp;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) User *user;

@end

NS_ASSUME_NONNULL_END
