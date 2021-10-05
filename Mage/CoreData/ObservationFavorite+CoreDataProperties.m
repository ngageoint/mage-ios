//
//  ObservationFavorite+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationFavorite+CoreDataProperties.h"

@implementation ObservationFavorite (CoreDataProperties)

+ (NSFetchRequest<ObservationFavorite *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ObservationFavorite"];
}

@dynamic dirty;
@dynamic userId;
@dynamic favorite;
@dynamic observation;

@end
