//
//  ObservationFavorite+CoreDataProperties.h
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationFavorite.h"


NS_ASSUME_NONNULL_BEGIN

@interface ObservationFavorite (CoreDataProperties)

+ (NSFetchRequest<ObservationFavorite *> *)fetchRequest;

@property (nonatomic) BOOL dirty;
@property (nullable, nonatomic, copy) NSString *userId;
@property (nonatomic) BOOL favorite;
@property (nullable, nonatomic, retain) Observation *observation;

@end

NS_ASSUME_NONNULL_END
