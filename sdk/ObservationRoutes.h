//
//  ObservationRoutes.h
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RouteMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObservationRoutes : NSObject

+ (instancetype) singleton;

- (RouteMethod *) pull: (NSNumber *) eventId;
- (RouteMethod *) deleteRoute: (NSManagedObject *) observation;
- (RouteMethod *) createId: (NSManagedObject *) observation;
- (RouteMethod *) pushFavorite: (NSManagedObject *) observationFavorite;
- (RouteMethod *) pushImportant: (NSManagedObject *) important;

@end

NS_ASSUME_NONNULL_END
