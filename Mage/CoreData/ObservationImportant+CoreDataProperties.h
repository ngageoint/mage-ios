//
//  ObservationImportant+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationImportant.h"

@class Observation;

NS_ASSUME_NONNULL_BEGIN

@interface ObservationImportant (CoreDataProperties)

+ (NSFetchRequest<ObservationImportant *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *dirty;
@property (nullable, nonatomic, copy) NSNumber *important;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nullable, nonatomic, copy) NSString *reason;
@property (nullable, nonatomic, copy) NSString *userId;
@property (nullable, nonatomic, retain) Observation *observation;

@end

NS_ASSUME_NONNULL_END
