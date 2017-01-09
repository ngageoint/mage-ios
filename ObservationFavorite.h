//
//  ObservationFavorite+CoreDataClass.h
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Observation;

NS_ASSUME_NONNULL_BEGIN

@interface ObservationFavorite : NSManagedObject

+ (ObservationFavorite *) favoriteForUserId: (NSString *) userId inManagedObjectContext:(NSManagedObjectContext *) context;

@end

NS_ASSUME_NONNULL_END

#import "ObservationFavorite+CoreDataProperties.h"
