//
//  ObservationFavorite+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/20/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationFavorite.h"

@implementation ObservationFavorite

+ (ObservationFavorite *) favoriteForUserId: (NSString *) userId inManagedObjectContext:(NSManagedObjectContext *) context {
    ObservationFavorite *favorite = [ObservationFavorite MR_createEntityInContext:context];
    
    favorite.dirty = NO;
    favorite.favorite = YES;
    favorite.userId = userId;
    
    return favorite;
}

@end
