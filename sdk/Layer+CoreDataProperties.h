//
//  Layer+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/18/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Layer.h"

NS_ASSUME_NONNULL_BEGIN

@interface Layer (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *eventId;
@property (nullable, nonatomic, retain) NSString *formId;
@property (nullable, nonatomic, retain) NSNumber *loaded;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *remoteId;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSDictionary* file;
@property (nullable, nonatomic, retain) NSNumber *downloadedBytes;
@property (nonatomic) BOOL downloading;

@end

NS_ASSUME_NONNULL_END
